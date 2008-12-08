package format.abc;
import format.abc.Data;

class Reader {

	var i : haxe.io.Input;
	var opr : OpReader;

	public function new(i) {
		this.i = i;
		opr = new OpReader(i);
	}

	inline function readInt() {
		return opr.readInt();
	}

	inline function readIndex<T>() : Index<T> {
		return Idx(readInt());
	}

	function readIndexOpt<T>() : Null<Index<T>> {
		var i = readInt();
		return (i == 0) ? null : Idx(i);
	}

	function readList<T>(f) : Array<T> {
		var a = new Array<T>();
		var n = readInt();
		if( n == 0 )
			return a;
		for( i in 0...n-1 )
			a.push(f());
		return a;
	}

	function readList2<T>(f) : Array<T> {
		var a = new Array<T>();
		var n = readInt();
		for( i in 0...n )
			a.push(f());
		return a;
	}

	function readString() {
		return i.readString(readInt());
	}

	function readNamespace() {
		var k = i.readByte();
		var p = readIndex();
		return switch( k ) {
		case 0x05: NPrivate(p);
		case 0x08: NNamespace(p);
		case 0x16: NPublic(p);
		case 0x17: NInternal(p);
		case 0x18: NProtected(p);
		case 0x19: NExplicit(p);
		case 0x1A: NStaticProtected(p);
		default: throw "assert";
		}
	}

	function readNsSet() : NamespaceSet {
		var a = new Array();
		for( n in 0...i.readByte() )
			a.push(readIndex());
		return a;
	}

	function readName( k = -1 ) : Name {
		if( k == -1 ) k = i.readByte();
		return switch( k ) {
		case 0x07:
			var ns = readIndex();
			var id = readIndex();
			NName(id,ns);
		case 0x09:
			var id = readIndex();
			var ns = readIndex();
			NMulti(id,ns);
		case 0x0D:
			NAttrib(readName(0x07));
		case 0x0E:
			NAttrib(readName(0x09));
		case 0x0F:
			NRuntime(readIndex());
		case 0x10:
			NRuntimeLate;
		case 0x12:
			NAttrib(readName(0x11));
		case 0x1B:
			NMultiLate(readIndex());
		case 0x1C:
			NAttrib(readName(0x1B));
		case 0x1D:
			var id = readIndex();
			var params = readList(readIndex);
			NParams(id,params);
		default:
			throw "assert";
		}
	}

	function readValue(extra) {
		var idx = readInt();
		if( idx == 0 ) {
			if( extra && i.readByte() != 0 ) throw "assert";
			return null;
		}
		var n = i.readByte();
		return switch(n) {
		case 0x01: VString(Idx(idx));
		case 0x03: VInt(Idx(idx));
		case 0x04: VUInt(Idx(idx));
		case 0x06: VFloat(Idx(idx));
		case 0x05, 0x08, 0x16, 0x17, 0x18, 0x19, 0x1A: VNamespace(n,Idx(idx));
		case 0x0A: if( idx != 0x0A ) throw "assert"; VBool(false);
		case 0x0B: if( idx != 0x0B ) throw "assert"; VBool(true);
		case 0x0C: if( idx != 0x0C ) throw "assert"; VNull;
		default: throw "assert";
		}
	}

	function readMethodType() : MethodType {
		var nargs = i.readByte();
		var tret = readIndexOpt();
		var targs = new Array();
		for( i in 0...nargs )
			targs.push(readIndexOpt());
		var dname = readIndexOpt();
		var flags = i.readByte();
		if( flags == 0 )
			return {
				args : targs,
				ret : tret,
				extra : null,
			};
		var dparams = null, pnames = null;
		if( (flags & 0x08) != 0 )
			dparams = readList2(callback(readValue,true));
		if( (flags & 0x80) != 0 ) {
			pnames = new Array();
			for( i in 0...nargs )
				pnames.push(readIndexOpt());
		}
		return {
			args : targs,
			ret : tret,
			extra : {
				native : (flags & 0x20) != 0,
				variableArgs : (flags & 0x04) != 0,
				argumentsDefined : (flags & 0x01) != 0,
				usesDXNS : (flags & 0x40) != 0,
				newBlock : (flags & 0x02) != 0,
				unused : (flags & 0x10) != 0,
				debugName : dname,
				defaultParameters : dparams,
				paramNames : pnames,
			},
		};
	}

	function readMetadata() {
		var name = readIndex();
		var data = readList2(readIndexOpt);
		var a = new Array();
		for( i in data )
			a.push({ n : i, v : readIndex() });
		return {
			name : name,
			data : a,
		};
	}

	function readField() : Field {
		var name = readIndex();
		var kind = i.readByte();
		var slot = readInt();
		var f;
		switch( kind & 0xF ) {
		case 0x00, 0x06:
			var t = readIndexOpt();
			var v = readValue(false);
			f = FVar(t,v,kind == 0x06);
		case 0x01, 0x02, 0x03:
			var mt = readIndex();
			var final = kind & 0x10 != 0;
			var over = kind & 0x20 != 0;
			var kind = switch( kind & 0xF  ) {
				case 0x01: KNormal;
				case 0x02: KGetter;
				case 0x03: KSetter;
				default: throw "assert";
			}
			f = FMethod(mt,kind,final,over);
		case 0x04:
			f = FClass(readIndex());
		case 0x05:
			f = FFunction(readIndex());
		default:
			throw "assert";
		};
		var metas = null;
		if( (kind & 0x40) != 0 )
			metas = readList2(readMetadata);
		return {
			name : name,
			slot : slot,
			kind : f,
			metadatas : metas,
		};
	}

	function readClass() : ClassDef {
		var name = readIndex();
		var csuper = readIndexOpt();
		var flags = i.readByte();
		var ns = null;
		if( (flags & 0x08) != 0 ) ns = readIndex();
		var interfs = readList2(readIndex);
		var construct = readIndex();
		var fields = readList2(readField);
		return {
			name : name,
			superclass : csuper,
			interfaces : interfs,
			constructor : construct,
			fields : fields,
			namespace : ns,
			isSealed : (flags & 0x01) != 0,
			isFinal : (flags & 0x02) != 0,
			isInterface : (flags & 0x04) != 0,
			statics : null,
			staticFields : null,
		};
	}

	function readInit() : Init {
		return {
			method : readIndex(),
			fields : readList2(readField),
		};
	}

	function readTryCatch() : TryCatch {
		return {
			start : readInt(),
			end : readInt(),
			handle : readInt(),
			type : readIndexOpt(),
			variable : readIndexOpt(),
		};
	}

	function readFunction() : Function {
		var t = readIndex();
		var ss = readInt();
		var nregs = readInt();
		var init_scope = readInt();
		var max_scope = readInt();
		var size = readInt();
		var code = new Array();
		for( _ in 0...size )
			code.push(OUnknown(i.readByte()));
		var trys = readList2(readTryCatch);
		var locals = readList2(readField);
		return {
			type : t,
			maxStack : ss,
			nRegs : nregs,
			initScope : init_scope,
			maxScope : max_scope,
			code : code,
			trys : trys,
			locals : locals,
		};
	}


	public function read() {
		if( i.readUInt30() != 0x002E0010 )
			throw "invalid header";
		var data = new ABCData();
		data.ints = readList(opr.readInt32);
		data.uints = readList(opr.readInt32);
		data.floats = readList(i.readDouble);
		data.strings = readList(readString);
		data.namespaces = readList(readNamespace);
		data.nssets = readList(readNsSet);
		data.names = readList(callback(readName,-1));
		data.methodTypes = readList2(readMethodType);
		data.metadatas = readList2(readMetadata);
		data.classes = readList2(readClass);
		for( c in data.classes ) {
			c.statics = readIndex();
			c.staticFields = readList2(readField);
		}
		data.inits = readList2(readInit);
		data.functions = readList2(readFunction);
		return data;
	}

}