using Pkg
Pkg.instantiate()
using Preferences
set_preferences!("libMad", "gpu"=>ARGS[1])
