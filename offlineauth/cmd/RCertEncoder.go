package main

import (
	"encoding/hex"
	"fmt"
	"github.com/robinburkhard/rainsdeleg/common"
	"os"
)

func main() {
	certpath := os.Args[1]
	cert, _ := common.LoadCertificatePEM(certpath)
	rawcert := cert.Raw
	hexstring := hex.EncodeToString(rawcert)
	fmt.Println(":A: . [ :cert: :rhine: :zoneAuth: :noHash: "+hexstring+" ]")
}
