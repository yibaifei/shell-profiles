#!/bin/sh

url=$1

set -u
set -e

[[ $1 ]] || {
    echo "$0 <url>"
    exit 0
}

tmpfile=/tmp/$(basename $0).$$
rm -f $tmpfile
index=0

if [[ $url =~ ^[0-9]+$ ]]; then
	sno=$url
else
	{
	echo -e "\n请记住要使用的序号，并按 q 退出！\n"
	for no in $(grep "HTTP REQUEST.*$url," *audit*.log -h | sort | awk -F '\\]\\[' '{print $8}'); do
	    let index=$index+1
	    for line in "$(grep -E "${no}.*HTTP (RESPONSE|REQUEST)" *audit*.log -h)"; do
		echo $index $no >> $tmpfile
		echo -e "==== $index ===== \n$line"
	    done
	done } | less

	echo -n "请输入要查看的日志序号: "
	read select
	echo select: $select
	sno=$(awk '$1=='$select'{print $2}' $tmpfile)
fi

    #{[serverid: 8,lastsysdate: 20190521,sysdate: 20190522,orderdate: 20190522,status: 0,],}
    #{[poststr: 00690014935,custid: 120499900001,regflag: 0,bondreg: 0,opendate: 20101208,market: 0,secuid: 0690014935,name: 罗照珍,fundid: 0,secuseq: 0,secuidtype: 1,nrsecuid: 0283013458,nrseat: ,],[poststr: 1E000179930,custid: 120499900001,regflag: 1,bondreg: 0,opendate: 20101208,market: 1,secuid: E000179930,name: 罗照珍,fundid: 0,secuseq: 0,secuidtype: 1,nrsecuid: A481322344,nrseat: ,],}

# 入参处理
input=$(grep "$sno" * -h | sort | awk -F '\\]\\[' '$10=="PSVIN"' | grep -o "{.*}")

# 电商中台处理
dszt=$(grep "$sno" * -h | sort | awk -F '\\]\\[' '$12~/DSZT/' | head -4 | grep -Eo "url=[^,]+|strRes:.*"  | sed 's/url=/"dbghttp":\[\["/;N;s/\nstrRes:/",0,/;s/$/\]\]/')
#echo $dszt


counter=$(while read line; do
	echo -n "[$(echo $line | awk -F '\\]\\[' '{print $12}' | sed 's/Counter-//g'),"
	if echo $line | grep -q 'Counter response:'; then
		echo -n "0,"
		echo -n $line | sed 's/.*Counter response: //' | sed 's/\[[0-9]\+\]//g' | sed 's/:\s*/:/g;s/,]/]/g;s/,}/}/g' | sed 's/:\s*\[\([^]]*\)[^,]*/:\1/g' | sed 's/\([^][{}:,]\+\):\([^][{},]*\)/"\1":"\2"/g' | tr '{}[]' '[]{}' | sed 's/"cli_remark":"MAC"[^,]\+/"cli_remark":""/g' | sed 's/"cli_remark\([^,]*,\)\{7\}/"cli_remark":"",/g'
#"cli_remark":"19566588658",000000,5.3.0.66097+5.3.0.20200514172806,000000,"02":"00":"00":"00":"00":"00",FF53A10B-98DD-44A1-8610-9A4C90A2E5D7,10.101.203.1,
#"cli_remark":"MAC":"005056B9501A;HD":"6000C29E931CF6F71E7E1B4F9B1C77E5;LIP":"10.101.222.28;APP":"CSCTRADEFORMULA.EXE;CPUINFO":"GENUINEINTEL_INTEL(R) XEON(R) GOLD 6126 CPU @ 2.60GHZ;CPUID":"1FABFBFF00050654;PCN":"JFJXQ-TYB-JY28;PI":"A_REMOVABLE;VOL":"C;OSV":"MICROSOFT WINDOWS SERVER 2008 R2",
	elif echo $line | grep -q ': error code:'; then
		# error code:-980023096 , error msg :-980023096[-980023096]客户密码错误或账号密码不匹配。
		echo -n $line | sed 's/^.*error code://' | sed 's/\(.*\) , error msg :\(.*\)$/\1,\"\2\"/g'
	elif echo $line | grep -q "maCli_OpenTable ErrCode=.*, ErrMsg=.*"; then
		# maCli_OpenTable ErrCode=-1, ErrMsg=会话凭证已过有效期,
		echo -n $line | sed 's/^.*maCli_OpenTable ErrCode=\([^,]\+\), ErrMsg=\([^,]\+\).*$/\1,\"\2\"/g'
	fi
	echo -n "],"
done <<EOF | sed 's/],$/]/g'
	$(grep "$sno" * -h | sort | awk -F '\\]\\[' '$10=="ACTIN" && $12~/^Counter-/')
EOF
)

res=$(
echo -n "{"
[[ $dszt ]] && echo -n "$dszt,"
[[ $counter != "[,]" ]] && echo -n "\"dbgcounter\":[$counter],"
echo ${input:1} | sed 's/\*\{6\}/123321/g'
)

#echo $res

# 功能号去重
#res=$(echo $res | perl -MJSON -e '
#	$ref = decode_json(<>);
#	$d = $ref->{dbgcounter};
#
#	$uniq{$_->[0]}++ foreach (@$d);
#	@u = grep { $uniq{$_} > 1 } keys %uniq;
#
#	foreach $i (0..@$d-1) {
#		if($d->[$i]->[0] ~~ @u and $d->[$i]->[1] != 0) {
#			splice(@$d, $i, 1);
#			last;
#		}
#	}
#
#	print encode_json($ref);
#')

#echo $dup

echo $res
#rm -f $tmpfile
