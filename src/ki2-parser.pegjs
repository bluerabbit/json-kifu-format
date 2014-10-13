{
	function toN(ss){
		return parseInt(ss.join(""), 10);
	}
	function zenToN(s){
		return "０１２３４５６７８９".indexOf(s);
	}
	function kanToN(s){
		return "〇一二三四五六七八九".indexOf(s);
	}
	function kanToN2(s){
		switch(s.length){
			case 1:
				return "〇一二三四五六七八九十".indexOf(s);
			case 2:
				return "〇一二三四五六七八九十".indexOf(s[1])+10;
			default:
				throw "21以上の数値に対応していません";
		}
	}
	function kindToCSA(kind){
		if(kind[0]=="成"){
			return {
				"香": "NY",
				"桂": "NK",
				"銀": "NG"
			}[kind[1]];
		}
		return {
			"歩": "FU",
			"香": "KY",
			"桂": "KE",
			"銀": "GI",
			"金": "KI",
			"角": "KA",
			"飛": "HI",
			"玉": "OU",
			"王": "OU",
			"と": "TO",
			"杏": "NY",
			"圭": "NK",
			"全": "NG",
			"馬": "UM",
			"竜": "RY",
			"龍": "RY"
		}[kind];
	}
	function soutaiToRelative(str){
		return {
			"左": "L",
			"直": "C",
			"右": "R",
		}[str] || "";
	}
	function dousaToRelative(str){
		return {
			"上": "U",
			"寄": "C",
			"引": "D",
		}[str] || "";
	}
	function presetToString(preset){
		return {
			"平手": "HIRATE", 
			"香落ち": "KY",
			"右香落ち": "KY_R",
			"角落ち": "KA",
			"飛車落ち": "HI",
			"飛香落ち": "HIKY",
			"二枚落ち": "2",
			"三枚落ち": "3",
			"四枚落ち": "4",
			"五枚落ち": "5",
			"左五枚落ち": "5_L",
			"六枚落ち": "6",
			"八枚落ち": "8",
			"十枚落ち": "10",
			"その他": "OTHER",
		}[preset.replace(/\s/g, "")];
	}
	function makeHand(str){
		var kinds = str.replace(/　$/, "").split("　");
		var ret = {};
		for(var i=0; i<kinds.length; i++){
			ret[kindToCSA(kinds[i][0])] = kinds[i].length==1?1:kanToN2(kinds[i].slice(1));
		}
		return ret;
	}
}

kifu
 = headers:header* ini:initialboard? headers2:header* moves:moves res:result? {
 	var ret = {header:{}, moves:moves, result:res};
	for(var i=0; i<headers.length; i++){
		ret.header[headers[i].k]=headers[i].v;
	}
	for(var i=0; i<headers2.length; i++){
		ret.header[headers2[i].k]=headers2[i].v;
	}
	if(ini){
		ret.initial = ini;
	}else if(ret.header["手合割"]){
		var preset = presetToString(ret.header["手合割"]);
		if(preset!="OTHER") ret.initial={preset: preset};
	}
	if(ret.initial && ret.initial.data){
		if(ret.header["手番"]){
			ret.initial.data.color="下先".indexOf(ret.header["手番"])>=0 ? true : false;
		}else{
			ret.initial.data.color = true;
		}
		ret.initial.data.hands = [{}, {}];
		if(ret.header["先手の持駒"] || ret.header["下手の持駒"]){
			ret.initial.data.hands[0] = makeHand(ret.header["先手の持駒"] || ret.header["下手の持駒"]);
			delete ret.header["先手の持駒"];
			delete ret.header["下手の持駒"];
		}
		if(ret.header["後手の持駒"] || ret.header["上手の持駒"]){
			ret.initial.data.hands[1] = makeHand(ret.header["後手の持駒"] || ret.header["上手の持駒"]);
			delete ret.header["先手の持駒"];
			delete ret.header["下手の持駒"];
		}
	}
	return ret;
}

header
 = key:[^：\r\n]+ "：" value:nonl* nl+ {return {k:key.join(""), v:value.join("")}} / te:[先後上下] "手番" nl {return {k:"手番",v:te}}
initialboard = (" " nonl* nl)? ("+" nonl* nl)? lines:ikkatsuline+ ("+" nonl* nl)? {
	var ret = [];
	for(var i=0; i<9; i++){
		var line = [];
		for(var j=0; j<9; j++){
			line.push(lines[j][8-i]);
		}
		ret.push(line);
	}
	return {preset: "OTHER", data: {board:ret}};
}
ikkatsuline = "|" masu:masu+ "|" nonl+ nl { return masu; }
masu = c:teban k:piece {return {color:c, kind:k}} / " ・" { return {} }
teban = (" "/"+"/"^"){return true} / ("v"/"V"){return false}

moves = hd:firstboard tl:move* {tl.unshift(hd); return tl;}

firstboard = c:comment* pointer? {return c.length==0 ? {} : {comments:c}}
move = line:line c:comment* pointer? (nl / " ")* {
	var ret = {move: line};
	if(c.length>0) ret.comments=cl;
	return ret;
}

pointer = "&" nonl* nl

line = [▲△] f:fugou (nl / " ")*  {return f}
fugou = pl:place pi:piece sou:soutai? dou:dousa? pro:("成"/"不成")? da:"打"? {
	var ret = {piece: pi};
	if(pl.same){
		ret.same = true;
	}else{
		ret.to = pl;
	}
	if(pro)ret.promote=pro=="成";
	if(da){
		ret.relative = "H";
	}else{
		var rel = soutaiToRelative(sou)+dousaToRelative(dou);
		if(rel!="") ret.relative=rel;
	}
	return ret;
}
place = x:num y:numkan {return {x:x,y:y}} / "同" "　"? {return {same:true}}
piece = pro:"成"? p:[歩香桂銀金角飛王玉と杏圭全馬竜龍] {return kindToCSA((pro||"")+p)}
soutai = [左直右]
dousa = [上寄引]

num = n:[１２３４５６７８９] {return zenToN(n);}
numkan = n:[一二三四五六七八九] {return kanToN(n);}

comment = "*" comm:nonl* nl {return comm.join("")}

result = "まで" [0-9]+ "手" res:("で" win:[先後上下] "手の勝ち" {return win} / "で中断" {return "中断"} / "詰") nl {return res}

nl = "\r"? "\n"
nonl = [^\r\n]
