# filecourier
A helper for automating repetitive tasks in Citrix Sharefile

## Usage
Filecourier comes with scripts to automate tasks. In order to have Filecourier run a script, you must modify the `programs` section of `run.config` to instruct it to do so. The following are example configurations for each of the tasks Filecourier can do.

### Move VHL Files
```
  "programs": {
    "move_vhl_files": {}
  }
```

### File Child Documents
```
  "programs": {
    "file_child_docs": {
      "children": [
        "Anna H",
        "Jacob K",
        "Donna B"
      ]
    }
  }
```

## Dependencies
- [Flask](http://flask.pocoo.org/)
- [Requests](http://docs.python-requests.org/en/master/)
