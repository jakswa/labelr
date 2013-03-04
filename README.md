# Labelr

![img](http://i.imgur.com/uYlEwNS.png)

This is a prettier github issue list. It does what it needs using Github's OAuth API, which means you have to allow it access for it to work.

After authorization, the browser currently makes a single request to github, populating the issue and label lists with the results, and doing a simple sort based on top and bottom labels.

## Usage/Installation

I modified goauth.go to also serve up the needed html/javascript assets for this to work, so hopefully these instructions will be pretty easy to follow.

1. install [Go](http://golang.org/doc/install)
2. Clone the repo and cd to it
  - `git clone git@github.com:jakswa/labelr.git`
  - `cd labelr`
3. copy config.yml.example to config.yml, and fill out the client_id and client_secret values
  - you will probably need to create a [new Github OAuth App](https://github.com/settings/applications/new) for those values
  - if you've already created one, it'll be in your [list](https://github.com/settings/applications)
4. get the required go dependencies (assumes git is installed)
  -  `go get github.com/korbenzhang/goyaml`
5. run it!
  - `go run goauth.go`
6. point your browser at it (localhost:8080 is the default, as of this writing)
