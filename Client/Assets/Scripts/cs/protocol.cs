using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Diagnostics;
using zprotobuf;
namespace protocol {

public abstract class wirep:iwirep {
	protected override wiretree _wiretree() {
		return serializer.instance();
	}
}

public class error_n:wirep {
	public int cmd;
	public int errno;

	public override string _name() {
		return "error_n";
	}
	protected override int _encode_field(ref zdll.args args)  {
		switch (args.tag) {
		case 1:
			return write(ref args, cmd);
		case 2:
			return write(ref args, errno);
		default:
			return zdll.ERROR;
		}
	}
	protected override int _decode_field(ref zdll.args args)  {
		switch (args.tag) {
		case 1:
			return read(ref args, out cmd);
		case 2:
			return read(ref args, out errno);
		default:
			return zdll.ERROR;
		}
	}
}
public class auth_r:wirep {
	public string account;
	public string passwd;
	public int server;

	public override string _name() {
		return "auth_r";
	}
	protected override int _encode_field(ref zdll.args args)  {
		switch (args.tag) {
		case 1:
			return write(ref args, account);
		case 2:
			return write(ref args, passwd);
		case 3:
			return write(ref args, server);
		default:
			return zdll.ERROR;
		}
	}
	protected override int _decode_field(ref zdll.args args)  {
		switch (args.tag) {
		case 1:
			return read(ref args, out account);
		case 2:
			return read(ref args, out passwd);
		case 3:
			return read(ref args, out server);
		default:
			return zdll.ERROR;
		}
	}
}
public class auth_a:wirep {
	public int uid;
	public string gate;
	public string token;

	public override string _name() {
		return "auth_a";
	}
	protected override int _encode_field(ref zdll.args args)  {
		switch (args.tag) {
		case 1:
			return write(ref args, uid);
		case 2:
			return write(ref args, gate);
		case 3:
			return write(ref args, token);
		default:
			return zdll.ERROR;
		}
	}
	protected override int _decode_field(ref zdll.args args)  {
		switch (args.tag) {
		case 1:
			return read(ref args, out uid);
		case 2:
			return read(ref args, out gate);
		case 3:
			return read(ref args, out token);
		default:
			return zdll.ERROR;
		}
	}
}
public class serializer:wiretree {

	private static serializer inst = null;

	private const string def = "\x65\x72\x72\x6f\x72\x5f\x6e\x20\x30\x78\x31\x30\x30\x30\x30\x20\x7b\xa\x9\x2e\x63\x6d\x64\x3a\x69\x6e\x74\x65\x67\x65\x72\x20\x31\xa\x9\x2e\x65\x72\x72\x6e\x6f\x3a\x69\x6e\x74\x65\x67\x65\x72\x20\x32\xa\x7d\xa\xa\xa\x61\x75\x74\x68\x5f\x72\x20\x30\x78\x31\x31\x30\x30\x30\x20\x7b\xa\x9\x2e\x61\x63\x63\x6f\x75\x6e\x74\x3a\x73\x74\x72\x69\x6e\x67\x20\x31\xa\x9\x2e\x70\x61\x73\x73\x77\x64\x3a\x73\x74\x72\x69\x6e\x67\x20\x32\xa\x9\x2e\x73\x65\x72\x76\x65\x72\x3a\x69\x6e\x74\x65\x67\x65\x72\x20\x33\xa\x7d\xa\xa\x61\x75\x74\x68\x5f\x61\x20\x30\x78\x31\x31\x30\x30\x31\x20\x7b\xa\x9\x2e\x75\x69\x64\x3a\x69\x6e\x74\x65\x67\x65\x72\x20\x31\xa\x9\x2e\x67\x61\x74\x65\x3a\x73\x74\x72\x69\x6e\x67\x20\x32\xa\x9\x2e\x74\x6f\x6b\x65\x6e\x3a\x73\x74\x72\x69\x6e\x67\x20\x33\xa\x7d\xa\xa\xa";
	private serializer():base(def) {

	}

	public static serializer instance() {
		if (inst == null)
			inst = new serializer();
		return inst;
	}
}

}
