package aggserver

import (
	"context"
	"errors"
	"log"

	_ "github.com/rhine-team/RHINE-Prototype/offlineAuth/cbor"
	pf "github.com/rhine-team/RHINE-Prototype/offlineAuth/components/aggregator"
	"github.com/rhine-team/RHINE-Prototype/offlineAuth/rhine"
)

type AggServer struct {
	pf.UnimplementedAggServiceServer
	AggManager *rhine.AggManager
}

func (s *AggServer) DSRetrieval(ctx context.Context, in *pf.RetrieveDSALogRequest) (*pf.RetrieveDSALogResponse, error) {
	res := &pf.RetrieveDSALogResponse{}

	dsaBytes, dsaSigs, err := s.AggManager.Dsalog.DSRetrieve(in.RequestedZones, s.AggManager.GetPrivKey(), s.AggManager.DB)
	if err != nil {
		return res, err
	}

	res = &pf.RetrieveDSALogResponse{
		DSAPayload:    dsaBytes,
		DSASignatures: dsaSigs,
	}
	return res, nil

}

func (s *AggServer) SubmitNDS(ctx context.Context, in *pf.SubmitNDSRequest) (*pf.SubmitNDSResponse, error) {
	res := &pf.SubmitNDSResponse{}

	log.Printf("SubmitNDS service called with RID: %s\n", rhine.EncodeBase64(in.Rid))
	//log.Printf("Received request %+v", in)

	// Construct rhine representation of Lwits
	var LogWitnessList []rhine.Lwit
	for _, lwit := range in.Lwits {
		newLwit := rhine.Lwit{
			Rsig: &rhine.RhineSig{
				Data:      lwit.Data,
				Signature: lwit.Sig,
			},
			NdsBytes: lwit.NdsHash,
			Log:      &rhine.Log{Name: lwit.Log},
			LogList:  lwit.DesignatedLogs,
		}
		LogWitnessList = append(LogWitnessList, newLwit)
	}
	//log.Printf("List of all log witnesses: %+v \n", LogWitnessList)

	// Parse NDS
	nds, errNDS := rhine.BytesToNds(in.Nds)
	if errNDS != nil {
		return res, errNDS
	}
	//log.Println("NDS deserialized:", nds)

	// Check Correct Signature on NDS
	if err := nds.VerifyNDS(s.AggManager.Ca.Pubkey); err != nil {
		return res, err
	}

	log.Println("NDS is correctly signed.")

	// Step 13 Checks
	if !rhine.VerifyLwitSlice(LogWitnessList, s.AggManager.LogMap) {
		return res, errors.New("Aggregator: One of the LogWitness failed verification!")
	}

	//log.Println("Log witnesses are valid")

	// Match Lwit and NDS
	if !nds.MatchWithLwits(LogWitnessList) {
		return res, errors.New("Aggregator: Lwit did not match with NDS")
	}

	log.Println("Log witness list matches NDS")

	acfm, errAccNDS := s.AggManager.AcceptNDSAndStore(nds)
	if errAccNDS != nil {
		return res, errAccNDS
	}

	log.Println("NDS Submission has been accepted.")

	acfmBytes, erracfm := acfm.ConfirmToTransportBytes()
	if erracfm != nil {
		return res, erracfm
	}

	res = &pf.SubmitNDSResponse{
		Acfmg: acfmBytes,
		Rid:   in.Rid,
	}

	log.Printf("SubmitNDSResponse sent for RID: %s\n", rhine.EncodeBase64(in.Rid))

	return res, nil
}
