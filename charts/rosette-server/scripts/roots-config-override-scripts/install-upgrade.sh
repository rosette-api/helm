#!/bin/bash
OPERATION_INFO_DIR=$(dirname $0)
source "$OPERATION_INFO_DIR/utils.sh"
OVERRIDE="/override"
BACKUP="/backup"
ROOTS_DIR="/roots"
if [[ ! -d "$ROOTS_DIR" ]]; then
  error "Roots volume not found"
  exit 1
fi
if [[ -d "$BACKUP" ]]; then
  info "Backup volume found"
else
  warn "Backup volume not found. Using roots volume"
  BACKUP="/$ROOTS_DIR/backup"
  if [[ ! -d "$BACKUP" ]]; then
    info "Creating backup directory on roots volume"
    mkdir "$BACKUP"
  fi
fi
# On install delete previous backups
if [[ "$HELM_RELEASE_REVISION" -eq 1 ]]; then
  info "Previous backup found for ${HELM_RELEASE_NAME}. As a new release is being installed the previous backup is deleted."
  rm -rf "$BACKUP/$HELM_RELEASE_NAME"
fi
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

startlogging "$WORKDIR/install-upgrade"
# These files contain the addition, deletion and override operations to complete. They are using the information from the 'rootsOverride'
# section of "values.yaml" and constructed in "templates/hooks/cm-roots-override-files.yaml".
info "Copying operation files to $WORKDIR"
cp "$OPERATION_INFO_DIR/new-entry.txt" "$WORKDIR/new-entry.txt"
cp "$OPERATION_INFO_DIR/override-entry.txt" "$WORKDIR/override-entry.txt"
cp "$OPERATION_INFO_DIR/delete-entry.txt" "$WORKDIR/delete-entry.txt"
echo "$SEPARATOR" > "$WORKDIR/separator.txt"

info "----Processing entry DELETION operations----"
while read -r line; do
  ROOT=""
  ROOT=$(sed "s#\(.*\)${SEPARATOR}.*${SEPARATOR}.*#\1#" <<< $line)
  ROOT_VERSION=""
  ROOT_VERSION=$(sed "s#.*${SEPARATOR}\(.*\)${SEPARATOR}.*#\1#" <<< $line)
  TARGET_PATH=""
  TARGET_PATH=$(sed "s#.*${SEPARATOR}.*${SEPARATOR}/\?\(.*\)#\1#" <<< $line)
  TARGET_PATH_INVALID=""
  TARGET_PATH_INVALID=$(validate-target-path "$TARGET_PATH")
  if [[ $ROOT == "rnirnt" ]]; then
    ROOT="rni-rnt"
  fi
  TARGET="$ROOTS_DIR/$ROOT/$ROOT_VERSION/$TARGET_PATH"
  SKIP_DELETION=0
  if [[ "$TARGET_PATH_INVALID" -eq 1 ]]; then
    warn "Skipping deletion of $ROOT/$ROOT_VERSION/$TARGET_PATH. Target path is invalid. Make sure it is not empty or '/' and it doesn't contain '..'"
    SKIP_DELETION=1
  fi
  if [[ ! -e "$TARGET" ]]; then
    warn "Skipping deletion of $ROOT/$ROOT_VERSION/$TARGET_PATH as it doesn't exist"
    SKIP_DELETION=1
  fi
  if [[ $SKIP_DELETION -eq 0 ]]; then
    BACKUP_DIR="$ROOT/$ROOT_VERSION/$TARGET_PATH"
    BACKUP_DIR="$DELETED_DIR/${BACKUP_DIR//\//-}"
    mkdir -p "$BACKUP_DIR"
    cp -r "$TARGET" "$BACKUP_DIR"
    rm -rf "${TARGET}"
    sed -i "1 iDEL${SEPARATOR}${ROOT}${SEPARATOR}${ROOT_VERSION}${SEPARATOR}${TARGET_PATH}" "$REVERSE_OPS"
    info "Deleted $ROOT/$ROOT_VERSION/$TARGET_PATH"
  fi
done < "$WORKDIR/delete-entry.txt"

info "----Processing entry ADDITION operations----"
while read -r line; do
  ROOT=""
  ROOT=$(sed "s#\(.*\)${SEPARATOR}.*${SEPARATOR}.*${SEPARATOR}.*#\1#" <<< $line)
  ROOT_VERSION=""
  ROOT_VERSION=$(sed "s#.*${SEPARATOR}\(.*\)${SEPARATOR}.*${SEPARATOR}.*#\1#" <<< $line)
  ORIGIN_PATH=""
  ORIGIN_PATH=$(sed "s#.*${SEPARATOR}.*${SEPARATOR}/\?\(.*\)${SEPARATOR}.*#\1#" <<< $line)
  TARGET_PATH=""
  TARGET_PATH=$(sed "s#.*${SEPARATOR}.*${SEPARATOR}.*${SEPARATOR}/\?\(.*\)#\1#" <<< $line)
  TARGET_PATH_INVALID=""
  TARGET_PATH_INVALID=$(validate-target-path "$TARGET_PATH")
  if [[ $ROOT == "rnirnt" ]]; then
    ROOT="rni-rnt"
  fi
  TARGET="$ROOTS_DIR/$ROOT/$ROOT_VERSION/$TARGET_PATH"
  ORIGIN="$OVERRIDE/$ORIGIN_PATH"
  SKIP_ADDITION=0
  if [[ ! -d "$OVERRIDE" ]]; then
    warn "Skipping adding $ORIGIN_PATH to $ROOT/$ROOT_VERSION/$TARGET_PATH. No override volume found."
    SKIP_ADDITION=1
  fi
  if [[ "$TARGET_PATH_INVALID" -eq 1 ]]; then
    warn "Skipping adding $ORIGIN_PATH to $ROOT/$ROOT_VERSION/$TARGET_PATH. Target path is invalid. Make sure it is not empty or '/' and it doesn't contain '..'"
    SKIP_ADDITION=1
  fi
  if [[ -e "$TARGET" ]]; then
    warn "Skipping adding $ORIGIN_PATH to $ROOT/$ROOT_VERSION/$TARGET_PATH as a file already exists there"
    SKIP_ADDITION=1
  fi
  if [[ ! -e "$ORIGIN" ]]; then
    warn "Skipping adding $ORIGIN_PATH to $ROOT/$ROOT_VERSION/$TARGET_PATH as $ORIGIN_PATH does not exist in the override volume"
    SKIP_ADDITION=1
  fi
  if [[ $SKIP_ADDITION -eq 0 ]]; then
    cp -r "$ORIGIN" "$TARGET"
    sed -i "1 iADD${SEPARATOR}${ROOT}${SEPARATOR}${ROOT_VERSION}${SEPARATOR}${TARGET_PATH}" "$REVERSE_OPS"
    info "Added $ORIGIN_PATH to $ROOT/$ROOT_VERSION/$TARGET_PATH"
  fi
done < "$WORKDIR/new-entry.txt"

info "----Processing entry OVERRIDE operations----"
while read -r line; do
  ROOT=""
  ROOT=$(sed "s#\(.*\)${SEPARATOR}.*${SEPARATOR}.*${SEPARATOR}.*#\1#" <<< $line)
  ROOT_VERSION=""
  ROOT_VERSION=$(sed "s#.*${SEPARATOR}\(.*\)${SEPARATOR}.*${SEPARATOR}.*#\1#" <<< $line)
  ORIGIN_PATH=""
  ORIGIN_PATH=$(sed "s#.*${SEPARATOR}.*${SEPARATOR}/\?\(.*\)${SEPARATOR}.*#\1#" <<< $line)
  TARGET_PATH=""
  TARGET_PATH=$(sed "s#.*${SEPARATOR}.*${SEPARATOR}.*${SEPARATOR}/\?\(.*\)#\1#" <<< $line)
  TARGET_PATH_INVALID=""
  TARGET_PATH_INVALID=$(validate-target-path "$TARGET_PATH")
  if [[ $ROOT == "rnirnt" ]]; then
    ROOT="rni-rnt"
  fi
  TARGET="$ROOTS_DIR/$ROOT/$ROOT_VERSION/$TARGET_PATH"
  ORIGIN="$OVERRIDE/$ORIGIN_PATH"
  SKIP_OVERRIDE=0
  if [[ ! -d "$OVERRIDE" ]]; then
    warn "Skipping overriding $ROOT/$ROOT_VERSION/$TARGET_PATH with $ORIGIN_PATH. No override volume found."
    SKIP_OVERRIDE=1
  fi
  if [[ "$TARGET_PATH_INVALID" -eq 1 ]]; then
    warn "Skipping overriding $ROOT/$ROOT_VERSION/$TARGET_PATH with $ORIGIN_PATH. Target path is invalid. Make sure it is not empty or '/' and it doesn't contain '..'"
    SKIP_OVERRIDE=1
  fi
  if [[ ! -e "$TARGET" ]]; then
    warn "$ROOT/$ROOT_VERSION/$TARGET_PATH doesn't exist. Skipping override."
    SKIP_OVERRIDE=1
  fi
  if [[ ! -e "$ORIGIN" ]]; then
    warn "$ORIGIN_PATH doesn't exist in override volume. Cannot overwrite $ROOT/$ROOT_VERSION/$TARGET_PATH. Skipping override."
    SKIP_OVERRIDE=1
  fi
  if [[ -f "$TARGET" ]]; then
    if [[ ! -f "$ORIGIN" ]]; then
      warn "$ROOT/$ROOT_VERSION/$TARGET_PATH is a file. It cannot be overwritten by $ORIGIN_PATH because it is not a file. Skipping override."
      SKIP_OVERRIDE=1
    fi
  fi
  if [[ -d "$TARGET" ]]; then
    if [[ ! -d "$ORIGIN" ]]; then
      warn "$ROOT/$ROOT_VERSION/$TARGET_PATH is a directory. It cannot be overwritten by $ORIGIN_PATH because it is not a directory. Skipping override."
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
    info "Overwritten $ROOT/$ROOT_VERSION/$TARGET_PATH with $ORIGIN_PATH"
  fi
done < "$WORKDIR/override-entry.txt"

info "Rolling the Rosette Server deployment"
rollout-restart-rosette-server-deployment
