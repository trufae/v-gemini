module gemini

pub const (
	default_port = 1965
	default_cert = 'cert.pem'
	default_key  = 'key.pem'
)

pub enum StatusCode {
	input     = 10
	success   = 20
	not_found = 51
}
