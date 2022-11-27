# emacs-command-server
A minimal file based RPC server for Emacs. The typical client for usage is Talon.

## Workflow

```mermaid
sequenceDiagram
    autonumber
    
    participant client
    note right of client: Talon
    participant filesystem
    participant server
    note right of server: Emacs

    client->>+filesystem: write command into request.json
    client->>+server: trigger keybind

    par
        server->>+filesystem: read request.json
        filesystem-->>-server: request.json

        alt waitForFinish is true
            server->>server: run command
            server->>filesystem: write response.json
        else waitForFinish is false
            server->>filesystem: write response.json
            server->>server: run command
        end

        and

        loop every 25ms
          client->>+filesystem: ask for response.json
          filesystem-->>-client: response.json
        end

    end
```

See `example-client.sh` for an example of using the shell as a client.

### Caveats
 - global!
;; TODO: globalized minor mode that is always all or nothing?

 - isearch

### Unknowns
- Does it work on Windows?
