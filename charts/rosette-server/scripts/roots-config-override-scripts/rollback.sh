#!/bin/bash
OPERATION_INFO_DIR=$(dirname $0)
source "$OPERATION_INFO_DIR/utils.sh"
ROOTS_DIR="/roots"
if [[ ! -d "$ROOTS_DIR" ]]; then
  error "Roots volume not found"
  exit 1
fi
BACKUP="/backup"
if [[ ! -d "$BACKUP" ]]; then
  warn "No backup volume found"
  if [[ -d "$ROOTS_DIR/backup" ]]; then
    info "Roots volume has backup directory. Using it as the backup volume"
    BACKUP="$ROOTS_DIR/backup"
  else
    error "Backup volume not found"
    exit 1
  fi
fi
RELEASE_BACKUP="$BACKUP/$HELM_RELEASE_NAME"
if [[ ! -d "$RELEASE_BACKUP" ]]; then
  error "Backup volume doesn't have a a directory for ${HELM_RELEASE_NAME} release with the previous changes. These are required for rollback."
  exit 1
fi
CURRENT_REVISION=0
for revision in $(ls $RELEASE_BACKUP); do
  _REVISION=$(sed "s#revision-\(.*\)#\1#" <<< $revision)
  if [[ $_REVISION -gt $CURRENT_REVISION ]]; then
    CURRENT_REVISION=$_REVISION
  fi
done
DESIRED_REVISION=$HELM_RELEASE_REVISION
HELM_RELEASE_REVISION=$((CURRENT_REVISION + 1))
info "Rollback found that current version is $CURRENT_REVISION, the new rollback revision number is $HELM_RELEASE_REVISION and the desired rollback version is $DESIRED_REVISION"
WORKDIR="$BACKUP/$HELM_RELEASE_NAME/revision-$HELM_RELEASE_REVISION"
if [[ -d "$WORKDIR" ]]; then
  error "Backup volume already has rollback data for $HELM_RELEASE_NAME and revision $HELM_RELEASE_REVISION"
  exit 1
fi
info "Creating $WORKDIR"
mkdir -p "$WORKDIR"
REVERSE_OPS="$WORKDIR/reverse.operations"
echo -e "-" > "$REVERSE_OPS"
DELETED_DIR="$WORKDIR/deleted"
mkdir -p "$DELETED_DIR"
OVERWRITTEN_DIR="$WORKDIR/overwritten"
mkdir -p "$OVERWRITTEN_DIR"

startlogging "$WORKDIR/rollback"
info "Creating rollback marker"
ROLLBACK_MARKER="$WORKDIR/rollback.marker"
echo -e "in-progress" > "$ROLLBACK_MARKER"
echo "$SEPARATOR" > "$WORKDIR/separator.txt"

while [[ $CURRENT_REVISION -gt $DESIRED_REVISION ]]; do
  info "-----The current revision of the rosette roots is ${CURRENT_REVISION}----"
  REVISION_DIRECTORY="$RELEASE_BACKUP/revision-${CURRENT_REVISION}"
  DO_REVERSE_OPERATIONS=1
  if [[ ! -d "$REVISION_DIRECTORY" ]]; then
    warn "No data found for ${REVISION_DIRECTORY}. This can be because override of the rosette root directories wasn't enabled for this revision. If no changes were made to the roots during this revision this shouldn't cause a problem. Skipping rollback of revision ${CURRENT_REVISION}"
    DO_REVERSE_OPERATIONS=0
    CURRENT_REVISION=$((CURRENT_REVISION - 1))
  fi
  # The current revision is a rollback
  if [[ -f "$REVISION_DIRECTORY/rollback.marker" ]]; then
    info "The revision is a rollback revision"
    ROLLBACK_TARGET_REVISION=$(cat "$REVISION_DIRECTORY/rollback.marker")
    if [[ "$ROLLBACK_TARGET_REVISION" != "in-progress" ]]; then
      if [[ $ROLLBACK_TARGET_REVISION -ge $DESIRED_REVISION ]]; then
        info "Roots state in revision ${CURRENT_REVISION} is the same as in revision ${ROLLBACK_TARGET_REVISION}. Continuing from revision ${ROLLBACK_TARGET_REVISION}"
        CURRENT_REVISION=$ROLLBACK_TARGET_REVISION
        DO_REVERSE_OPERATIONS=0
      fi
    else
      warn "This rollback wasn't completed correctly. No target revision found. Defaulting to rolling back operations"
    fi
  fi
  if [[ $DO_REVERSE_OPERATIONS -eq 1 ]]; then
    if [[ -f "$REVISION_DIRECTORY/reverse.operations" ]]; then
      info "Reversing operations of revision ${CURRENT_REVISION}"
      REVISION_SEPARATOR=""
      if [[ -f "$REVISION_DIRECTORY/separator.txt" ]]; then
        REVISION_SEPARATOR=$(cat "$REVISION_DIRECTORY/separator.txt")
      else
        warn "No separator string found in revision ${CURRENT_REVISION}. Defaulting to current separator ${SEPARATOR}"
        REVISION_SEPARATOR=$SEPARATOR
      fi
      while read -r line; do
        if [[ $line != "-" ]]; then # last line, do nothing
          OP=""
          OP=$(sed "s#\(.*\)${REVISION_SEPARATOR}.*${REVISION_SEPARATOR}.*${REVISION_SEPARATOR}.*#\1#" <<< $line)
          ROOT=""
          ROOT=$(sed "s#.*${REVISION_SEPARATOR}\(.*\)${REVISION_SEPARATOR}.*${REVISION_SEPARATOR}.*#\1#" <<< $line)
          ROOT_VERSION=""
          ROOT_VERSION=$(sed "s#.*${REVISION_SEPARATOR}.*${REVISION_SEPARATOR}\(.*\)${REVISION_SEPARATOR}.*#\1#" <<< $line)
          TARGET_PATH=""
          TARGET_PATH=$(sed "s#.*${REVISION_SEPARATOR}.*${REVISION_SEPARATOR}.*${REVISION_SEPARATOR}\(.*\)#\1#" <<< $line)
          TARGET_PATH_INVALID=""
          TARGET_PATH_INVALID=$(validate-target-path "$TARGET_PATH")
          REVERSE_STEP=1
          if [[ $OP == "" ]] || [[ $ROOT == "" ]]  || [[ $ROOT_VERSION == "" ]]; then
            error "Invalid reverse operations data line: ${line}. Some required information is missing. The line should be <operation><separator><root><separator><root-version><separator><file-path>. Skipping the reversal of this operation"
            REVERSE_STEP=0
          fi
          if [[ "$TARGET_PATH_INVALID" -eq 1 ]]; then
            warn "Skipping reversing operation $OP of $ROOT/$ROOT_VERSION/$TARGET_PATH. Target path is invalid. Make sure it is not empty or '/' and it doesn't contain '..'"
            REVERSE_STEP=0
          fi
          if [[ $REVERSE_STEP -eq 1 ]]; then
            TARGET="$ROOTS_DIR/$ROOT/$ROOT_VERSION/$TARGET_PATH"
            OPERATION_VALID=0

            if [[ $OP == "ADD" ]]; then
              OPERATION_VALID=1
              info "Reversing ADDITION of $ROOT/$ROOT_VERSION/$TARGET_PATH. Deleting it."
              if [[ ! -e "$TARGET" ]]; then
                warn "Skipping deletion of $ROOT/$ROOT_VERSION/$TARGET_PATH as it doesn't exist"
              else
                BACKUP_DIR="$ROOT/$ROOT_VERSION/$TARGET_PATH"
                BACKUP_DIR="$DELETED_DIR/${BACKUP_DIR//\//-}"
                mkdir -p "$BACKUP_DIR"
                cp -r "$TARGET" "$BACKUP_DIR"
                rm -rf "${TARGET}"
                sed -i "1 iDEL${SEPARATOR}${ROOT}${SEPARATOR}${ROOT_VERSION}${SEPARATOR}${TARGET_PATH}" "$REVERSE_OPS"
                info "Deleted $ROOT/$ROOT_VERSION/$TARGET_PATH"
              fi
            fi

            if [[ $OP == "DEL" ]]; then
              OPERATION_VALID=1
              info "Reversing DELETION of $ROOT/$ROOT_VERSION/$TARGET_PATH. Re-adding it."
              REVISION_DELETED_DIR="$REVISION_DIRECTORY/deleted"
              OPERATION_BACKUP_DIR="$ROOT/$ROOT_VERSION/$TARGET_PATH"
              ENTRY_NAME=$(basename $TARGET_PATH)
              ORIGIN="$REVISION_DELETED_DIR/${OPERATION_BACKUP_DIR//\//-}/$ENTRY_NAME"
              SKIP_ADDITION=0
              if [[ -e "$TARGET" ]]; then
                warn "Skipping re-adding $ROOT/$ROOT_VERSION/$TARGET_PATH as a file already exists there"
                SKIP_ADDITION=1
              fi
              if [[ ! -e "$ORIGIN" ]]; then
                warn "Skipping re-adding $ROOT/$ROOT_VERSION/$TARGET_PATH as no backup was found"
                SKIP_ADDITION=1
              fi
              if [[ $SKIP_ADDITION -eq 0 ]]; then
                cp -r "$ORIGIN" "$TARGET"
                sed -i "1 iADD${SEPARATOR}${ROOT}${SEPARATOR}${ROOT_VERSION}${SEPARATOR}${TARGET_PATH}" "$REVERSE_OPS"
                info "Added the backup to $ROOT/$ROOT_VERSION/$TARGET_PATH"
              fi
            fi

            if [[ $OP == "OVR" ]]; then
              OPERATION_VALID=1
              info "Reversing OVERRIDE of $ROOT/$ROOT_VERSION/$TARGET_PATH. Overriding it with the backed up version."
              REVISION_OVERRIDE_DIR="$REVISION_DIRECTORY/overwritten"
              OPERATION_BACKUP_DIR="$ROOT/$ROOT_VERSION/$TARGET_PATH"
              ENTRY_NAME=$(basename $TARGET_PATH)
              ORIGIN="$REVISION_OVERRIDE_DIR/${OPERATION_BACKUP_DIR//\//-}/$ENTRY_NAME"
              SKIP_OVERRIDE=0
              if [[ ! -e "$TARGET" ]]; then
                warn "$ROOT/$ROOT_VERSION/$TARGET_PATH doesn't exist. Skipping override reversal."
                SKIP_OVERRIDE=1
              fi
              if [[ ! -e "$ORIGIN" ]]; then
                warn "No backup was found from the original override. Cannot overwrite $ROOT/$ROOT_VERSION/$TARGET_PATH. Skipping override reversal."
                SKIP_OVERRIDE=1
              fi
              if [[ -f "$TARGET" ]]; then
                if [[ ! -f "$ORIGIN" ]]; then
                  warn "$ROOT/$ROOT_VERSION/$TARGET_PATH is a file. It cannot be overwritten by the backup because it is not a file. Skipping override."
                  SKIP_OVERRIDE=1
                fi
              fi
              if [[ -d "$TARGET" ]]; then
                if [[ ! -d "$ORIGIN" ]]; then
                  warn "$ROOT/$ROOT_VERSION/$TARGET_PATH is a directory. It cannot be overwritten by the backup because it is not a directory. Skipping override."
                  SKIP_OVERRIDE=1
                fi
              fi
              if [[ $SKIP_OVERRIDE -eq 0 ]]; then
                BACKUP_DIR="$ROOT/$ROOT_VERSION/$TARGET_PATH"
                BACKUP_DIR="$OVERWRITTEN_DIR/${BACKUP_DIR//\//-}"
                mkdir -p "$BACKUP_DIR"
                cp -r "$TARGET" "$BACKUP_DIR"
                rm -rf "$TARGET"
                cp -r "$ORIGIN" "$TARGET"
                sed -i "1 iOVR${SEPARATOR}${ROOT}${SEPARATOR}${ROOT_VERSION}${SEPARATOR}${TARGET_PATH}" "$REVERSE_OPS"
                info "Overwritten $ROOT/$ROOT_VERSION/$TARGET_PATH with the backed up version"
              fi
            fi

            if [[ $OPERATION_VALID -eq 0 ]]; then
              error "Unknown operation $OP. Skipping reversal of $line"
            fi
          fi
        fi
      done < "$REVISION_DIRECTORY/reverse.operations"
    else
      error "No reverse operations file found in revision ${CURRENT_REVISION}. Cannot reverse changes. Skipping rollback of revision ${CURRENT_REVISION}"
    fi
    CURRENT_REVISION=$((CURRENT_REVISION - 1))
  fi
done
if [[ $CURRENT_REVISION -eq $DESIRED_REVISION ]]; then
  info "Done! Roots state is the same as it was at revision $DESIRED_REVISION"
  echo -e "$DESIRED_REVISION" > "$ROLLBACK_MARKER"
fi

info "Rolling the Rosette Server deployment"
rollout-restart-rosette-server-deployment