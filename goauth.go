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
  "github.com/wendal/goyaml"
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
  fmt.Println("setting client_id and client_secret from configs..")
  file,err := os.Open("config.yml")
  if err == nil { 
    fmt.Println("File opened without error, getting them there.")
    defer file.Close()

    r := bufio.NewReader(file)
    contents := make([]byte, 1024)
    numberOfBytes,_ := r.Read(contents)
    yerr := goyaml.Unmarshal(contents[:numberOfBytes], &config)
    if yerr != nil { panic(yerr) }
  } else {
    config.ClientId = os.Getenv("CLIENT_ID")
    config.ClientSecret = os.Getenv("CLIENT_SECRET")
    fmt.Println("could not find config.yml! hope you set them in the ENV...")
  }

  fmt.Println("config loaded in to be this client id and secret: ", config)
  return &config
}

func main() {
  loadConfig()
  http.HandleFunc("/oauth", codeHandler)
  http.HandleFunc("/", indexHandler)
  http.HandleFunc("/index.html", indexHandler)
  http.HandleFunc("/application.js", handleJS)
  http.HandleFunc("/application.coffee", handleCoffee)

  s := os.Getenv("PORT")
  if (len(s) == 0) { s = "80" }
  
  fmt.Println("server starting on port ", s, "...")
  err := http.ListenAndServe(":" + s, nil)
  if err  != nil { panic(err) }

  fmt.Println("done. exiting...")
}
