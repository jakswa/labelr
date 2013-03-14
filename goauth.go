// This is meant to be a simple server
// that takes oauth "code" parameters,
// sends it to github's API, and proxies
// the response back to the browser
package main

import (
  "fmt"
  "net/http"
  "net/url"
  "flag"
  "bufio"
  "io"
  "os"
  "github.com/wendal/goyaml"
)

type Config struct {
  ClientId      string
  ClientSecret  string
}

var (
  config = Config{}
  port *string = flag.String("port", "80", "port to listen on")
)

func codeHandler(w http.ResponseWriter, r *http.Request) {
  code := r.FormValue("code")

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

func handleJS(w http.ResponseWriter, r *http.Request) {
  http.ServeFile(w,r,"application.js")
}
func handleCoffee(w http.ResponseWriter, r *http.Request) {
  http.ServeFile(w,r,"application.coffee")
}
func indexHandler(w http.ResponseWriter, r *http.Request) {
  http.ServeFile(w,r,"index.html")
}

func loadConfig() *Config {
  flag.Parse()
  
  file,err := os.Open("config.yml")
  if err != nil { panic(err) }
  defer file.Close()

  r := bufio.NewReader(file)
  contents := make([]byte, 1024)
  numberOfBytes, err := r.Read(contents)
  yerr := goyaml.Unmarshal(contents[:numberOfBytes], &config)
  if yerr != nil { panic(yerr) }

  return &config
}

func main() {
  loadConfig()
  http.HandleFunc("/oauth", codeHandler)
  http.HandleFunc("/", indexHandler)
  http.HandleFunc("/index.html", indexHandler)
  http.HandleFunc("/application.js", handleJS)
  http.HandleFunc("/application.coffee", handleCoffee)
  flag.Parse()
  fmt.Println("server started on port ", ":" + *port)
  http.ListenAndServe(":" + *port, nil)

  fmt.Println("done. exiting...")
}
