%376
:- module(path_NOIFAZ,
	[
	    path/2,
	    spend_time/1
	],[]).

:- use_package(library(tabling('LowLevelInterface'))).
:- use_module(engine(hiord_rt), 
	[
	    '$meta_call'/1
	]).

:- use_module(library(prolog_sys)).

path(X,Y) :- 
	put_tabled_call(path(X,Y),Sid,Test),
	( var(Test) ->
	    ('$meta_call'('path_NOIFAZ:path0'(path(X,Y),Sid)); test_complete(Sid))
	;
	    true
	),
	is_lider(Sid),
	consume_answer(path(X,Y),Sid,_).

path0(path(X,Y),Sid) :- 
	edge(X,Z),
	put_tabled_call(path(Z,Y),Sid2,Test),
	( var(Test) ->
	    ('$meta_call'('path_NOIFAZ:path0'(path(Z,Y),Sid2));test_complete(Sid2))
	;
	    true
	),
	tabled_call(Sid,Sid2,'path_NOIFAZ:path1',[X,Y,Z],F,_),
	'$meta_call'(F).

path0(path(X,Y),Sid) :-
	edge(X,Y),
	new_answer(path(X,Y),Sid,F,_),
	'$meta_call'(F).

path1(path(X,Y),Sid,[Z,Y,X]) :-
	new_answer(path(Z,Y),Sid,F,_),
	'$meta_call'(F).

spend_time(T) :- 
	statistics(runtime,[_,_]),
	(path(1,_); true),
	statistics(runtime,[_,T]).

edge(1,20000).
edge(20000,20001).
edge(20001,20002).
edge(20002,20003).
edge(20003,20004).
edge(20004,20005).
edge(20005,20006).
edge(20006,20007).
edge(20007,20008).
edge(20008,20009).
edge(20009,20010).
edge(20010,20011).
edge(20011,20012).
edge(20012,20013).
edge(20013,20014).
edge(20014,20015).
edge(20015,20016).
edge(20016,20017).
edge(20017,20018).
edge(20018,20019).
edge(20019,20020).
edge(20020,20021).
edge(20021,20022).
edge(20022,20023).
edge(20023,20024).
edge(20024,20025).
edge(20025,20026).
edge(20026,20027).
edge(20027,20028).
edge(20028,20029).
edge(20029,20030).
edge(20030,20031).
edge(20031,20032).
edge(20032,20033).
edge(20033,20034).
edge(20034,20035).
edge(20035,20036).
edge(20036,20037).
edge(20037,20038).
edge(20038,20039).
edge(20039,20040).
edge(20040,20041).
edge(20041,20042).
edge(20042,20043).
edge(20043,20044).
edge(20044,20045).
edge(20045,20046).
edge(20046,20047).
edge(20047,20048).
edge(20048,20049).
edge(20049,20050).
edge(20050,20051).
edge(20051,20052).
edge(20052,20053).
edge(20053,20054).
edge(20054,20055).
edge(20055,20056).
edge(20056,20057).
edge(20057,20058).
edge(20058,20059).
edge(20059,20060).
edge(20060,20061).
edge(20061,20062).
edge(20062,20063).
edge(20063,20064).
edge(20064,20065).
edge(20065,20066).
edge(20066,20067).
edge(20067,20068).
edge(20068,20069).
edge(20069,20070).
edge(20070,20071).
edge(20071,20072).
edge(20072,20073).
edge(20073,20074).
edge(20074,20075).
edge(20075,20076).
edge(20076,20077).
edge(20077,20078).
edge(20078,20079).
edge(20079,20080).
edge(20080,20081).
edge(20081,20082).
edge(20082,20083).
edge(20083,20084).
edge(20084,20085).
edge(20085,20086).
edge(20086,20087).
edge(20087,20088).
edge(20088,20089).
edge(20089,20090).
edge(20090,20091).
edge(20091,20092).
edge(20092,20093).
edge(20093,20094).
edge(20094,20095).
edge(20095,20096).
edge(20096,20097).
edge(20097,20098).
edge(20098,20099).
edge(20099,20100).
edge(20100,20101).
edge(20101,20102).
edge(20102,20103).
edge(20103,20104).
edge(20104,20105).
edge(20105,20106).
edge(20106,20107).
edge(20107,20108).
edge(20108,20109).
edge(20109,20110).
edge(20110,20111).
edge(20111,20112).
edge(20112,20113).
edge(20113,20114).
edge(20114,20115).
edge(20115,20116).
edge(20116,20117).
edge(20117,20118).
edge(20118,20119).
edge(20119,20120).
edge(20120,20121).
edge(20121,20122).
edge(20122,20123).
edge(20123,20124).
edge(20124,20125).
edge(20125,20126).
edge(20126,20127).
edge(20127,20128).
edge(20128,20129).
edge(20129,20130).
edge(20130,20131).
edge(20131,20132).
edge(20132,20133).
edge(20133,20134).
edge(20134,20135).
edge(20135,20136).
edge(20136,20137).
edge(20137,20138).
edge(20138,20139).
edge(20139,20140).
edge(20140,20141).
edge(20141,20142).
edge(20142,20143).
edge(20143,20144).
edge(20144,20145).
edge(20145,20146).
edge(20146,20147).
edge(20147,20148).
edge(20148,20149).
edge(20149,20150).
edge(20150,20151).
edge(20151,20152).
edge(20152,20153).
edge(20153,20154).
edge(20154,20155).
edge(20155,20156).
edge(20156,20157).
edge(20157,20158).
edge(20158,20159).
edge(20159,20160).
edge(20160,20161).
edge(20161,20162).
edge(20162,20163).
edge(20163,20164).
edge(20164,20165).
edge(20165,20166).
edge(20166,20167).
edge(20167,20168).
edge(20168,20169).
edge(20169,20170).
edge(20170,20171).
edge(20171,20172).
edge(20172,20173).
edge(20173,20174).
edge(20174,20175).
edge(20175,20176).
edge(20176,20177).
edge(20177,20178).
edge(20178,20179).
edge(20179,20180).
edge(20180,20181).
edge(20181,20182).
edge(20182,20183).
edge(20183,20184).
edge(20184,20185).
edge(20185,20186).
edge(20186,20187).
edge(20187,20188).
edge(20188,20189).
edge(20189,20190).
edge(20190,20191).
edge(20191,20192).
edge(20192,20193).
edge(20193,20194).
edge(20194,20195).
edge(20195,20196).
edge(20196,20197).
edge(20197,20198).
edge(20198,20199).
edge(20199,20200).
edge(20200,20201).
edge(20201,20202).
edge(20202,20203).
edge(20203,20204).
edge(20204,20205).
edge(20205,20206).
edge(20206,20207).
edge(20207,20208).
edge(20208,20209).
edge(20209,20210).
edge(20210,20211).
edge(20211,20212).
edge(20212,20213).
edge(20213,20214).
edge(20214,20215).
edge(20215,20216).
edge(20216,20217).
edge(20217,20218).
edge(20218,20219).
edge(20219,20220).
edge(20220,20221).
edge(20221,20222).
edge(20222,20223).
edge(20223,20224).
edge(20224,20225).
edge(20225,20226).
edge(20226,20227).
edge(20227,20228).
edge(20228,20229).
edge(20229,20230).
edge(20230,20231).
edge(20231,20232).
edge(20232,20233).
edge(20233,20234).
edge(20234,20235).
edge(20235,20236).
edge(20236,20237).
edge(20237,20238).
edge(20238,20239).
edge(20239,20240).
edge(20240,20241).
edge(20241,20242).
edge(20242,20243).
edge(20243,20244).
edge(20244,20245).
edge(20245,20246).
edge(20246,20247).
edge(20247,20248).
edge(20248,20249).
edge(20249,20250).
edge(20250,20251).
edge(20251,20252).
edge(20252,20253).
edge(20253,20254).
edge(20254,20255).
edge(20255,20256).
edge(20256,20257).
edge(20257,20258).
edge(20258,20259).
edge(20259,20260).
edge(20260,20261).
edge(20261,20262).
edge(20262,20263).
edge(20263,20264).
edge(20264,20265).
edge(20265,20266).
edge(20266,20267).
edge(20267,20268).
edge(20268,20269).
edge(20269,20270).
edge(20270,20271).
edge(20271,20272).
edge(20272,20273).
edge(20273,20274).
edge(20274,20275).
edge(20275,20276).
edge(20276,20277).
edge(20277,20278).
edge(20278,20279).
edge(20279,20280).
edge(20280,20281).
edge(20281,20282).
edge(20282,20283).
edge(20283,20284).
edge(20284,20285).
edge(20285,20286).
edge(20286,20287).
edge(20287,20288).
edge(20288,20289).
edge(20289,20290).
edge(20290,20291).
edge(20291,20292).
edge(20292,20293).
edge(20293,20294).
edge(20294,20295).
edge(20295,20296).
edge(20296,20297).
edge(20297,20298).
edge(20298,20299).
edge(20299,20300).
edge(20300,20301).
edge(20301,20302).
edge(20302,20303).
edge(20303,20304).
edge(20304,20305).
edge(20305,20306).
edge(20306,20307).
edge(20307,20308).
edge(20308,20309).
edge(20309,20310).
edge(20310,20311).
edge(20311,20312).
edge(20312,20313).
edge(20313,20314).
edge(20314,20315).
edge(20315,20316).
edge(20316,20317).
edge(20317,20318).
edge(20318,20319).
edge(20319,20320).
edge(20320,20321).
edge(20321,20322).
edge(20322,20323).
edge(20323,20324).
edge(20324,20325).
edge(20325,20326).
edge(20326,20327).
edge(20327,20328).
edge(20328,20329).
edge(20329,20330).
edge(20330,20331).
edge(20331,20332).
edge(20332,20333).
edge(20333,20334).
edge(20334,20335).
edge(20335,20336).
edge(20336,20337).
edge(20337,20338).
edge(20338,20339).
edge(20339,20340).
edge(20340,20341).
edge(20341,20342).
edge(20342,20343).
edge(20343,20344).
edge(20344,20345).
edge(20345,20346).
edge(20346,20347).
edge(20347,20348).
edge(20348,20349).
edge(20349,20350).
edge(20350,20351).
edge(20351,20352).
edge(20352,20353).
edge(20353,20354).
edge(20354,20355).
edge(20355,20356).
edge(20356,20357).
edge(20357,20358).
edge(20358,20359).
edge(20359,20360).
edge(20360,20361).
edge(20361,20362).
edge(20362,20363).
edge(20363,20364).
edge(20364,20365).
edge(20365,20366).
edge(20366,20367).
edge(20367,20368).
edge(20368,20369).
edge(20369,20370).
edge(20370,20371).
edge(20371,20372).
edge(20372,20373).
edge(20373,20374).
edge(20374,20375).
edge(20375,20376).
edge(20376,20377).
edge(20377,20378).
edge(20378,20379).
edge(20379,20380).
edge(20380,20381).
edge(20381,20382).
edge(20382,20383).
edge(20383,20384).
edge(20384,20385).
edge(20385,20386).
edge(20386,20387).
edge(20387,20388).
edge(20388,20389).
edge(20389,20390).
edge(20390,20391).
edge(20391,20392).
edge(20392,20393).
edge(20393,20394).
edge(20394,20395).
edge(20395,20396).
edge(20396,20397).
edge(20397,20398).
edge(20398,20399).
edge(20399,20400).
edge(20400,20401).
edge(20401,20402).
edge(20402,20403).
edge(20403,20404).
edge(20404,20405).
edge(20405,20406).
edge(20406,20407).
edge(20407,20408).
edge(20408,20409).
edge(20409,20410).
edge(20410,20411).
edge(20411,20412).
edge(20412,20413).
edge(20413,20414).
edge(20414,20415).
edge(20415,20416).
edge(20416,20417).
edge(20417,20418).
edge(20418,20419).
edge(20419,20420).
edge(20420,20421).
edge(20421,20422).
edge(20422,20423).
edge(20423,20424).
edge(20424,20425).
edge(20425,20426).
edge(20426,20427).
edge(20427,20428).
edge(20428,20429).
edge(20429,20430).
edge(20430,20431).
edge(20431,20432).
edge(20432,20433).
edge(20433,20434).
edge(20434,20435).
edge(20435,20436).
edge(20436,20437).
edge(20437,20438).
edge(20438,20439).
edge(20439,20440).
edge(20440,20441).
edge(20441,20442).
edge(20442,20443).
edge(20443,20444).
edge(20444,20445).
edge(20445,20446).
edge(20446,20447).
edge(20447,20448).
edge(20448,20449).
edge(20449,20450).
edge(20450,20451).
edge(20451,20452).
edge(20452,20453).
edge(20453,20454).
edge(20454,20455).
edge(20455,20456).
edge(20456,20457).
edge(20457,20458).
edge(20458,20459).
edge(20459,20460).
edge(20460,20461).
edge(20461,20462).
edge(20462,20463).
edge(20463,20464).
edge(20464,20465).
edge(20465,20466).
edge(20466,20467).
edge(20467,20468).
edge(20468,20469).
edge(20469,20470).
edge(20470,20471).
edge(20471,20472).
edge(20472,20473).
edge(20473,20474).
edge(20474,20475).
edge(20475,20476).
edge(20476,20477).
edge(20477,20478).
edge(20478,20479).
edge(20479,20480).
edge(20480,20481).
edge(20481,20482).
edge(20482,20483).
edge(20483,20484).
edge(20484,20485).
edge(20485,20486).
edge(20486,20487).
edge(20487,20488).
edge(20488,20489).
edge(20489,20490).
edge(20490,20491).
edge(20491,20492).
edge(20492,20493).
edge(20493,20494).
edge(20494,20495).
edge(20495,20496).
edge(20496,20497).
edge(20497,20498).
edge(20498,20499).
edge(20499,20500).
edge(20500,20501).
edge(20501,20502).
edge(20502,20503).
edge(20503,20504).
edge(20504,20505).
edge(20505,20506).
edge(20506,20507).
edge(20507,20508).
edge(20508,20509).
edge(20509,20510).
edge(20510,20511).
edge(20511,20512).
edge(20512,1).
