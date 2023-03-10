To restrict the endpoints that are exposed perform the following (this will expose a subset of the endpoints you are licensed for):
1. Create a configuration file in the `/config/rosapi` directory. For example `allowed-endpoints.yaml`
2. The contents will have a yaml list of endpoints to allow (note language is almost universally required)
```
endpoints:
- /entities
- /sentiment
- /language
```
Note: spacing is important.

3. Edit the file `/config/com.basistech.ws.worker.cfg` and add the following line:
   ```
   overrideEndpointsPathname=${rosapi.config}/rosapi/allowed-endpoints.yaml
   ```

   This will include the allowed endpoints into the configuration.

4. Restart Rosette Server