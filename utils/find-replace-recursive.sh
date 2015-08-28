# Finds *.php files with {FIND} and replaces them with {REPLACE}
# Also does not touch files which don't have the matching {FIND} in them as some scripts do

find ./ -type f -name '*.php' -print0 | xargs -0 grep '{FIND}' -l | xargs sed -i 's/{FIND}/{REPLACE}/g'