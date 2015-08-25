1. Receive PR with: SHA, CLONE URL, REPO NAME, deployment name (todo - use PR or branch name or something)
2. Pull down
3. check if it is registered with an existing deployment (by checking the deployment name that was passed in)
4. If it was not matched to an existing deployment, provision and env
5. lookup and find env matching deployment name and deploy to it

TODO
* cleanup for all stuff
* persistance of project information

ISSUES
* when docker machine doesn't work... often it's missing certs, etc.
* build doesn't rebuild even when code has changed
