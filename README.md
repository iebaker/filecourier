# filecourier
A helper for automating repetitive tasks in Citrix Sharefile

## Instructions
Filecourier executes Programs, which are python modules. A Filecourier Program should define the function `program(sharefile)` where `sharefile` is an instance of `ShareFileClient`. In order to have Filecourier execute some Programs, add their names (one per line) to `run.config` and then execute `run.command`. Filecourier
will open a window in the user's default browser in order to complete a Sharefile Login, and then proceed to execute the configured Programs sequentially.

## ShareFileClient API
- `ShareFileClient.list(folder)` returns a dictionary of `{subfolder: subfolder_id}` mappings for subfolders of `folder`
- `ShareFileClient.move(item, source, destination)` moves `item` from its location in `source` to `destination`
