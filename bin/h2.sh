#!/bin/sh

cd ../log

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
#sno=15597183143740170704700000003167

    #{[serverid: 8,lastsysdate: 20190521,sysdate: 20190522,orderdate: 20190522,status: 0,],}
    #{[poststr: 00690014935,custid: 120499900001,regflag: 0,bondreg: 0,opendate: 20101208,market: 0,secuid: 0690014935,name: 罗照珍,fundid: 0,secuseq: 0,secuidtype: 1,nrsecuid: 0283013458,nrseat: ,],[poststr: 1E000179930,custid: 120499900001,regflag: 1,bondreg: 0,opendate: 20101208,market: 1,secuid: E000179930,name: 罗照珍,fundid: 0,secuseq: 0,secuidtype: 1,nrsecuid: A481322344,nrseat: ,],}
input=$(fgrep "[$sno]" * -h | sort | awk -F '\\]\\[' '$10=="PSVIN"' | grep -o "{.*}")
#echo input: [$input]
dszt=$(fgrep "[$sno]" * -h | sort | awk -F '\\]\\[' '$12=="DSZT"' | grep -Eo "url=[^,]+|strRes:.*"  | sed 's/url=/"dbghttp":\[\["/;N;s/\nstrRes:/",0,/;s/$/\]\]/')
#echo dszt: [$dszt]


#{[acct_id[9081]:,acct_type[8987]:,breg_status[8935]:,channel_id[9082]:,cuacct_attr[8921]:1,cuacct_code[8920]:99047376,cust_code[8902]:110303004850,int_org[8911]:1103,session_id[8814]:1391rzrq_sf022002262002262359590000000001TbCo1359MbQ=f/pWkL4CMljwya9XzS/opxCNI4X5roo4Js9dzSMvg2o=,stk_trdacct[448]:0601457705,stkbd[625]:00,stkex[207]:0,stkpbu[8843]:,subsys_sn[8988]:105,trdacct_exid[8929]:,trdacct_name[8932]:测试850,trdacct_sn[8928]:,trdacct_status[8933]:,treg_status[8934]:,],[acct_id[9081]:,acct_type[8987]:,breg_status[8935]:,channel_id[9082]:,cuacct_attr[8921]:1,cuacct_code[8920]:99047376,cust_code[8902]:110303004850,int_org[8911]:1103,session_id[8814]:1391rzrq_sf022002262002262359590000000001TbCo1359MbQ=f/pWkL4CMljwya9XzS/opxCNI4X5roo4Js9dzSMvg2o=,stk_trdacct[448]:E014514841,stkbd[625]:10,stkex[207]:1,stkpbu[8843]:,subsys_sn[8988]:105,trdacct_exid[8929]:,trdacct_name[8932]:测试850,trdacct_sn[8928]:,trdacct_status[8933]:,treg_status[8934]:,],}

counter=$(while read line; do
	echo -n "[$(echo $line | awk -F '\\]\\[' '{print $12}' | sed 's/Counter-//g'),"
	if echo $line | grep -q 'Counter response:'; then
		echo -n "0,"
        echo -n $line | sed 's/.*Counter response: //' | sed 's/ //g;s/,]/]/g;s/,}/}/g' | sed 's/\([^][{}:,]\+\)\(\[[0-9]\+\]\):\([^][{}:,]*\)/"\1":"\3"/g' | tr '{}[]' '[]{}'
		#echo -n $line | sed 's/.*Counter response: //' | sed 's/ //g;s/,]/]/g;s/,}/}/g' | sed 's/\([^][{}:,]\+\)\(\[:\([^][{}:,]*\)/"\1":"\2"/g' | tr '{}[]' '[]{}'
	elif echo $line | grep -q ': error code:'; then
		# error code:-980023096 , error msg :-980023096[-980023096]客户密码错误或账号密码不匹配。
		echo -n $line | sed 's/^.*error code://' | sed 's/\(.*\) , error msg :\(.*\)$/\1,\"\2\"/g'
	#else
	#	:
	fi
	echo -n "],"
done <<EOF | sed 's/],$/]/g'
	$(grep "$sno" * -h | sort | awk -F '\\]\\[' '$10=="ACTIN" && $12~/^Counter-/')
EOF
)
#echo counter: [$counter]

echo -n "{"
[[ $dszt ]] && echo -n "$dszt,"
[[ $counter != "[,]" ]] && echo -n "\"dbgcounter\":[$counter],"
echo ${input:1} | sed 's/\*\{6\}/123321/g'

#rm -f $tmpfile
