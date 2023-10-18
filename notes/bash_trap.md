Usefull to to clean tmpfiles for example.

    :::sh
    #!/bin/sh
    # trap function
    _on_exit() {
        local exit_status=${1:-$?}
        # Do something
        exit $exit_status
    }
    
    trap "_on_exit" EXIT
    
    # your code
    
    exit 0;
