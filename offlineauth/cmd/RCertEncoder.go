package main

import (
	"crypto/x509"
	"encoding/hex"
	"fmt"
	"github.com/robinburkhard/rainsdeleg/ca"
	"github.com/robinburkhard/rainsdeleg/common"
	"golang.org/x/crypto/ed25519"
)

func main() {
	//certpath := os.Args[1]
	//cert, _ := common.LoadCertificatePEM(certpath)
	//rawcert := cert.Raw
	//hexstring := hex.EncodeToString(rawcert)
	//fmt.Println(":A: . [ :cert: :rhine: :zoneAuth: :noHash: "+hexstring+" ]")

	var pubkey []byte
	//pubkey, _ = base64.StdEncoding.DecodeString("45lUXSSPs+zgzYIu47YiLfBv0ngwiSPZvr75l8mhr6k=")
	pubkey = []byte{227, 153, 84, 93, 36, 143, 179, 236, 224, 205, 130, 46, 227, 182, 34, 45, 240, 111, 210, 120, 48, 137, 35, 217, 190, 190, 249, 151, 201, 161, 175, 169}

	var pubkeyt ed25519.PublicKey
	pubkeyt = pubkey

	//pubkeyt, _, _ = ed25519.GenerateKey(rand.Reader)
	//fmt.Println(reflect.TypeOf(pubkey))
	//var bytespkey interface{}
	//bytespkey, _ = hex.DecodeString("e399545d248fb3ece0cd822ee3b6222df06fd278308923d9bebef997c9a1afa9")

	ca_config := ca.Config{
		PrivateKeyAlgorithm:    "Ed25519",
		PrivateKeyPath:         "../test/testfulldata/ca.key",
		CertificatePath:        "../test/testfulldata/ca.cert",
		RootCertsPath:          "../test/testfulldata/roots/",
	}
	CA := ca.NewCA(ca_config)

	//var pubkey ed25519.PublicKey
	//pubkey, _ = bytespkey.(ed25519.PublicKey)

	csr := x509.CertificateRequest{
		PublicKey:                pubkeyt,
		DNSNames:                 []string{"ethz.ch."},
	}

	bytecert, err := CA.IssueCertificate(&csr, true)
	if err != nil {
		fmt.Println(err)
	}
	common.StoreCertificatePEM("testrcert.pem", bytecert )
	hexstring := hex.EncodeToString(bytecert)
	fmt.Println(":A: . [ :cert: :rhine: :zoneAuth: :noHash: "+hexstring+" ]")

}
