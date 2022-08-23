// Code generated by "stringer -type=Signature"; DO NOT EDIT.

package algorithmTypes

import "strconv"

func _() {
	// An "invalid array index" compiler error signifies that the constant values have changed.
	// Re-run the stringer command to generate them again.
	var x [1]struct{}
	_ = x[Ed25519-1]
	_ = x[Ed448-2]
}

const _Signature_name = "Ed25519Ed448"

var _Signature_index = [...]uint8{0, 7, 12}

func (i Signature) String() string {
	i -= 1
	if i < 0 || i >= Signature(len(_Signature_index)-1) {
		return "Signature(" + strconv.FormatInt(int64(i+1), 10) + ")"
	}
	return _Signature_name[_Signature_index[i]:_Signature_index[i+1]]
}