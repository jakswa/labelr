// This is meant to be a simple server
// that takes oauth "code" parameters,
// sends it to github's API, and proxies
// the response back to the browser
package main

import (
  "fmt"
  "net/http"
  "net/url"
  "bufio"
  "io"
  "os"
  "launchpad.net/goyaml"
)

type Config struct {
  ClientId      string
  ClientSecret  string
}

var (
  config = Config{}
)

func codeHandler(w http.ResponseWriter, r *http.Request) {
  code := r.FormValue("code")
  w.Header().Set("Access-Control-Allow-Origin", r.Header.Get("Origin"))

  // go get our OAuth token from github
  resp, _ := http.PostForm("https://github.com/login/oauth/access_token",
            url.Values{ "code": {code}, 
                        "client_id": {config.ClientId}, 
                        "client_secret": {config.ClientSecret}})
  defer resp.Body.Close()
  
  // replicate content-type header that browser sees
  w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
  // shove response out to user
  io.Copy(w, resp.Body)
}

func loadConfig() *Config {
  file,err := os.Open("config.yml")
  if err != nil { panic(err) }
  defer file.Close()

  r := bufio.NewReader(file)
  contents := make([]byte, 1024)
  numberOfBytes, err := r.Read(contents)
  fmt.Println("read file: ", string(contents))
  yerr := goyaml.Unmarshal(contents[:numberOfBytes], &config)
  if yerr != nil { panic(yerr) }

  fmt.Println("loaded config: ", config)
  return &config
}

func main() {
  loadConfig()
  http.HandleFunc("/oauth", codeHandler)
  http.ListenAndServe(":8088", nil)

  fmt.Println("done. exiting...")
}
