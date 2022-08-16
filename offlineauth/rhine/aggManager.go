package rhine

import (
	"crypto/ed25519"

	"crypto/rsa"

	"encoding/json"

	"io/ioutil"
	"log"

	badger "github.com/dgraph-io/badger/v3"
	"github.com/google/certificate-transparency-go/x509"
)

type AggManager struct {
	Agg     Agg
	privkey any
	PubKey  any

	CertPool *x509.CertPool
	LogMap   map[string]Log
	AggMap   map[string]Agg
	LogList  []string
	AggList  []string
	Ca       Authority

	Dsalog       *DSALog
	T            uint64
	RequestCache map[string]RememberRequest

	DB *badger.DB
}

type AggConfig struct {
	PrivateKeyAlgorithm string
	PrivateKeyPath      string
	ServerAddress       string
	RootCertsPath       string

	LogsName        []string
	LogsPubKeyPaths []string

	AggregatorName []string
	AggPubKeyPaths []string

	CAName       string
	CAServerAddr string
	CAPubKeyPath string

	KeyValueDBDirectory string
}

func LoadAggConfig(Path string) (AggConfig, error) {
	conf := AggConfig{}
	file, err := ioutil.ReadFile(Path)
	if err != nil {
		return AggConfig{}, err
	}
	if err = json.Unmarshal(file, &conf); err != nil {
		return AggConfig{}, err
	}

	return conf, nil
}

func NewAggManager(config AggConfig) *AggManager {
	if config.PrivateKeyAlgorithm == "" {
		log.Fatal("No private key alg in config")
	}
	var privKey interface{}
	var pubkey interface{}

	if config.PrivateKeyPath == "" {
		log.Fatalln("No private key path for aggregator private key!")
	} else {
		switch config.PrivateKeyAlgorithm {
		case "RSA":
			var err error
			privKey, err = LoadRSAPrivateKeyPEM(config.PrivateKeyPath)
			if err != nil {
				log.Fatal("Error loading private key: ", err)
			}
			pubkey = privKey.(*rsa.PrivateKey).Public()
		case "Ed25519":
			var err error
			privKey, err = LoadPrivateKeyEd25519(config.PrivateKeyPath)
			if err != nil {
				log.Fatal("Error loading private key: ", err)
			}
			pubkey = privKey.(ed25519.PrivateKey).Public()
		}
	}

	var AggCertPool *x509.CertPool
	AggCertPool, err := x509.SystemCertPool()
	if err == nil {
		AggCertPool = x509.NewCertPool()
	}

	// Load CA Pubkey
	caPk, _ := PublicKeyFromFile(config.CAPubKeyPath)

	// Open database (should be created if not existing yet)
	db, errdb := badger.Open(badger.DefaultOptions(config.KeyValueDBDirectory))
	if errdb != nil {
		log.Fatal(errdb)
	}
	// TODO When is db.Close() called ?!

	myagg := AggManager{
		privkey: privKey,
		PubKey:  pubkey,
		Agg: Agg{
			Name:   config.ServerAddress,
			Pubkey: pubkey,
		},
		Dsalog:   NewDSALog(),
		CertPool: AggCertPool,
		Ca: Authority{
			Name:   config.CAName,
			Pubkey: caPk,
		},
		DB: db,
	}

	files, err := ioutil.ReadDir(config.RootCertsPath)
	//log.Println("Files for trust root: ", files)
	if err != nil {
		log.Fatal("Error reading roots directory: ", err)
	}

	for _, file := range files {
		pemfile, _ := ioutil.ReadFile(config.RootCertsPath + file.Name())

		if myagg.CertPool.AppendCertsFromPEM(pemfile) {
			log.Println("Added " + file.Name() + " to trust root")
		}
	}

	myagg.LogMap = make(map[string]Log)
	myagg.AggMap = make(map[string]Agg)
	myagg.LogList = config.LogsName
	myagg.AggList = config.AggregatorName

	// Log map for pubkey
	for i, v := range config.LogsName {
		pk, _ := PublicKeyFromFile(config.LogsPubKeyPaths[i])
		myagg.LogMap[v] = Log{
			Name:   v,
			Pubkey: pk,
		}
	}

	// Aggr map for pubkey
	for i, v := range config.AggregatorName {
		pk, _ := PublicKeyFromFile(config.AggPubKeyPaths[i])
		myagg.AggMap[v] = Agg{
			Name:   v,
			Pubkey: pk,
		}
	}

	return &myagg
}

func (a *AggManager) AcceptNDSAndStore(n *Nds) (*Confirm, error) {
	// Construct a DSum out of Nds
	dsum := n.ConstructDSum()

	//log.Println("Dsum created: ", dsum)
	log.Println("Dsum created.")

	// Store new delegation
	// Note: We leave parent arguments on zero, because they are not needed (we know a parent exists already)
	//a.Dsalog.AddDelegationStatus(GetParentZone(n.Nds.Zone.Name), 0, []byte{}, n.Nds.Exp, n.Nds.Zone.Name, n.Nds.Al, n.Nds.TbsCert, a.DB)

	// Create AGG_Confirm
	aggc, errconf := CreateConfirm(0, n, a.Agg.Name, dsum, a.privkey)
	if errconf != nil {
		return nil, errconf
	}

	return aggc, nil
}

func (a *AggManager) GetPrivKey() any {
	return a.privkey
}
