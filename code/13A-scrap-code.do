
**************
*** SCRAPS ***
**************

* Description of this do-file:

* 	Instructions to get IPEDS names

**************
**************
**************


* Sometimes in the IPEDS tuition data, we find unitid's with no corresponding name here:

// import delimited "$git/data/original/ipeds/ipeds-2012.csv", clear stringcols(_all)

* This key comes from:
* https://github.com/huyouare/freebase-ipeds/blob/master/ipeds-2012.csv

* In that case, use this tool to find institution name:

* https://nces.ed.gov/ipeds/datacenter/Default.aspx?gotoReportId=6&fromIpeds=true
