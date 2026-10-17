/// Master list of Indian cities used to validate and normalise city names
/// (AI extraction, expense form, trip cities).
///
/// One city per line: `Canonical Name|State|alias1,alias2|CODE1,CODE2`
/// - Canonical names follow current official names (e.g. Prayagraj, Gurugram).
/// - Aliases cover old names and common spellings.
/// - Codes are IATA airport codes and major Indian Railways station codes that
///   identify the city served. Codes that are ambiguous between two cities
///   (e.g. TCR, HSR) are intentionally left out.
///
/// Keep aliases to multi-letter, unambiguous names: single common words (e.g.
/// "Ara", "Bid") would match unrelated text in addresses.
const String indianCitiesData = '''
Delhi|Delhi|New Delhi,Dilli,NCT Delhi,Delhi NCR,NCT of Delhi|DEL,NDLS,DLI,NZM,ANVT,DEE
Gurugram|Haryana|Gurgaon|GGN
Noida|Uttar Pradesh|Gautam Buddh Nagar|
Greater Noida|Uttar Pradesh||
Ghaziabad|Uttar Pradesh||GZB
Faridabad|Haryana||FDB
Sonipat|Haryana|Sonepat|
Panipat|Haryana||PNP
Karnal|Haryana||
Ambala|Haryana|Ambala Cantt|UMB
Kurukshetra|Haryana||
Rohtak|Haryana||
Hisar|Haryana|Hissar|HSS
Rewari|Haryana||
Yamunanagar|Haryana|Yamuna Nagar|
Panchkula|Haryana||
Bhiwani|Haryana||
Sirsa|Haryana||
Jind|Haryana||
Kaithal|Haryana||
Palwal|Haryana||
Manesar|Haryana||
Bahadurgarh|Haryana||
Chandigarh|Chandigarh||IXC,CDG
Mohali|Punjab|SAS Nagar,Sahibzada Ajit Singh Nagar|
Zirakpur|Punjab||
Amritsar|Punjab||ATQ,ASR
Ludhiana|Punjab||LUH,LDH
Jalandhar|Punjab|Jullundur|AIP,JUC
Patiala|Punjab||
Bathinda|Punjab|Bhatinda|BUP,BTI
Pathankot|Punjab||IXP,PTK
Hoshiarpur|Punjab||
Moga|Punjab||
Firozpur|Punjab|Ferozepur|
Phagwara|Punjab||
Kapurthala|Punjab||
Sangrur|Punjab||
Rajpura|Punjab||
Shimla|Himachal Pradesh|Simla|SLV
Manali|Himachal Pradesh||
Kullu|Himachal Pradesh|Bhuntar|KUU
Dharamshala|Himachal Pradesh|Dharamsala,Kangra,Gaggal,McLeod Ganj|DHM
Mandi|Himachal Pradesh||
Solan|Himachal Pradesh||
Baddi|Himachal Pradesh||
Hamirpur|Himachal Pradesh||
Palampur|Himachal Pradesh||
Chamba|Himachal Pradesh||
Dalhousie|Himachal Pradesh||
Kasauli|Himachal Pradesh||
Srinagar|Jammu and Kashmir||SXR
Jammu|Jammu and Kashmir|Jammu Tawi|IXJ,JAT
Katra|Jammu and Kashmir|Shri Mata Vaishno Devi Katra,Vaishno Devi|SVDK
Anantnag|Jammu and Kashmir||
Baramulla|Jammu and Kashmir||
Udhampur|Jammu and Kashmir||
Leh|Ladakh||IXL
Kargil|Ladakh||
Dehradun|Uttarakhand|Dehra Dun|DED,DDN
Haridwar|Uttarakhand|Hardwar|
Rishikesh|Uttarakhand||
Roorkee|Uttarakhand||
Haldwani|Uttarakhand||
Nainital|Uttarakhand||
Rudrapur|Uttarakhand||
Kashipur|Uttarakhand||
Mussoorie|Uttarakhand||
Pantnagar|Uttarakhand||PGH
Lucknow|Uttar Pradesh||LKO
Kanpur|Uttar Pradesh|Cawnpore|KNU,CNB
Agra|Uttar Pradesh||AGR,AGC
Varanasi|Uttar Pradesh|Banaras,Benares,Kashi|VNS,BSB
Prayagraj|Uttar Pradesh|Allahabad|IXD,PRYJ,ALD
Gorakhpur|Uttar Pradesh||GOP,GKP
Meerut|Uttar Pradesh||
Aligarh|Uttar Pradesh||
Bareilly|Uttar Pradesh||BEK
Moradabad|Uttar Pradesh||
Saharanpur|Uttar Pradesh||
Mathura|Uttar Pradesh||
Vrindavan|Uttar Pradesh|Brindavan|
Jhansi|Uttar Pradesh||
Ayodhya|Uttar Pradesh|Faizabad|AYJ
Firozabad|Uttar Pradesh||
Muzaffarnagar|Uttar Pradesh||
Shahjahanpur|Uttar Pradesh||
Rampur|Uttar Pradesh||
Etawah|Uttar Pradesh||
Mirzapur|Uttar Pradesh||
Bulandshahr|Uttar Pradesh||
Sitapur|Uttar Pradesh||
Hapur|Uttar Pradesh||
Unnao|Uttar Pradesh||
Rae Bareli|Uttar Pradesh|Raebareli|
Sultanpur|Uttar Pradesh||
Basti|Uttar Pradesh||
Azamgarh|Uttar Pradesh||
Ballia|Uttar Pradesh||
Jaunpur|Uttar Pradesh||
Ghazipur|Uttar Pradesh||
Bahraich|Uttar Pradesh||
Gonda|Uttar Pradesh||
Deoria|Uttar Pradesh||
Banda|Uttar Pradesh||
Fatehpur|Uttar Pradesh||
Orai|Uttar Pradesh||
Lalitpur|Uttar Pradesh||
Amroha|Uttar Pradesh||
Pilibhit|Uttar Pradesh||
Budaun|Uttar Pradesh|Badaun|
Bijnor|Uttar Pradesh||
Etah|Uttar Pradesh||
Mainpuri|Uttar Pradesh||
Hardoi|Uttar Pradesh||
Kannauj|Uttar Pradesh||
Farrukhabad|Uttar Pradesh||
Shamli|Uttar Pradesh||
Baghpat|Uttar Pradesh||
Jaipur|Rajasthan|Pink City|JAI
Jodhpur|Rajasthan||JDH
Udaipur|Rajasthan||UDR,UDZ
Kota|Rajasthan||KOTA
Ajmer|Rajasthan||KQH,AII
Bikaner|Rajasthan||BKB
Jaisalmer|Rajasthan||JSA,JSM
Alwar|Rajasthan||
Bhilwara|Rajasthan||
Sikar|Rajasthan||
Bharatpur|Rajasthan||
Pali|Rajasthan||
Barmer|Rajasthan||
Chittorgarh|Rajasthan|Chittaurgarh|
Sri Ganganagar|Rajasthan|Ganganagar,Shri Ganganagar|
Hanumangarh|Rajasthan||
Tonk|Rajasthan||
Sawai Madhopur|Rajasthan||
Mount Abu|Rajasthan|Abu Road|
Pushkar|Rajasthan||
Neemrana|Rajasthan||
Bhiwadi|Rajasthan||
Kishangarh|Rajasthan||
Banswara|Rajasthan||
Dungarpur|Rajasthan||
Jhunjhunu|Rajasthan||
Churu|Rajasthan||
Nagaur|Rajasthan||
Dausa|Rajasthan||
Beawar|Rajasthan||
Ahmedabad|Gujarat|Amdavad|AMD,ADI
Gandhinagar|Gujarat||
Surat|Gujarat||STV
Vadodara|Gujarat|Baroda|BDQ,BRC
Rajkot|Gujarat||RAJ,RJT
Bhavnagar|Gujarat||BHU
Jamnagar|Gujarat||JGA
Junagadh|Gujarat||
Bhuj|Gujarat||BHJ
Gandhidham|Gujarat|Kandla|IXY
Anand|Gujarat||
Nadiad|Gujarat||
Navsari|Gujarat||
Valsad|Gujarat||
Vapi|Gujarat||
Bharuch|Gujarat||
Ankleshwar|Gujarat||
Mehsana|Gujarat|Mahesana|
Palanpur|Gujarat||
Morbi|Gujarat|Morvi|
Surendranagar|Gujarat||
Porbandar|Gujarat||PBD
Godhra|Gujarat||
Dahod|Gujarat||
Veraval|Gujarat||
Dwarka|Gujarat||
Somnath|Gujarat||
Ekta Nagar|Gujarat|Kevadia,Kevadiya,Statue of Unity|
Daman|Dadra and Nagar Haveli and Daman and Diu||NMB
Diu|Dadra and Nagar Haveli and Daman and Diu||DIU
Silvassa|Dadra and Nagar Haveli and Daman and Diu||
Mumbai|Maharashtra|Bombay|BOM,CSMT,CSTM,BCT,LTT,BDTS
Navi Mumbai|Maharashtra|New Bombay|NMI
Thane|Maharashtra||TNA
Kalyan|Maharashtra||KYN
Panvel|Maharashtra||PNVL
Vasai-Virar|Maharashtra|Vasai,Virar|
Bhiwandi|Maharashtra||
Mira-Bhayandar|Maharashtra|Mira Road,Bhayandar,Mira Bhayandar|
Ulhasnagar|Maharashtra||
Pune|Maharashtra|Poona|PNQ,PUNE
Pimpri-Chinchwad|Maharashtra|Pimpri Chinchwad,Pimpri,Chinchwad,PCMC|
Nagpur|Maharashtra||NAG,NGP
Nashik|Maharashtra|Nasik|ISK
Chhatrapati Sambhajinagar|Maharashtra|Aurangabad,Sambhajinagar|IXU,AWB
Solapur|Maharashtra|Sholapur|SSE
Kolhapur|Maharashtra||KLH
Sangli|Maharashtra||
Satara|Maharashtra||
Amravati|Maharashtra||
Akola|Maharashtra||
Jalgaon|Maharashtra||JLG
Dhule|Maharashtra||
Ahilyanagar|Maharashtra|Ahmednagar|
Latur|Maharashtra||
Nanded|Maharashtra||NDC
Parbhani|Maharashtra||
Chandrapur|Maharashtra||
Wardha|Maharashtra||
Yavatmal|Maharashtra||
Gondia|Maharashtra||GDB
Bhandara|Maharashtra||
Ratnagiri|Maharashtra||
Sindhudurg|Maharashtra||SDW
Alibag|Maharashtra|Alibaug|
Lonavala|Maharashtra|Lonavla|
Shirdi|Maharashtra||SAG
Malegaon|Maharashtra||
Jalna|Maharashtra||
Beed|Maharashtra||
Dharashiv|Maharashtra|Osmanabad|
Baramati|Maharashtra||
Karad|Maharashtra||
Ichalkaranji|Maharashtra||
Mahabaleshwar|Maharashtra||
Goa|Goa||GOI,GOX
Panaji|Goa|Panjim|
Margao|Goa|Madgaon|MAO
Vasco da Gama|Goa|Vasco|VSG
Mapusa|Goa||
Bengaluru|Karnataka|Bangalore,Bengalooru|BLR,SBC,YPR,SMVB
Mysuru|Karnataka|Mysore|MYQ,MYS
Mangaluru|Karnataka|Mangalore|IXE,MAQ,MAJN
Hubballi|Karnataka|Hubli,Hubli-Dharwad|HBX,UBL
Dharwad|Karnataka||
Belagavi|Karnataka|Belgaum|IXG,BGM
Kalaburagi|Karnataka|Gulbarga|GBI
Ballari|Karnataka|Bellary|
Vijayapura|Karnataka|Bijapur|
Shivamogga|Karnataka|Shimoga|RQY
Tumakuru|Karnataka|Tumkur|
Davanagere|Karnataka|Davangere|
Udupi|Karnataka||
Manipal|Karnataka||
Hassan|Karnataka||
Mandya|Karnataka||
Chitradurga|Karnataka||
Raichur|Karnataka||
Bidar|Karnataka||IXX
Hosapete|Karnataka|Hospet|
Hampi|Karnataka||
Kolar|Karnataka||
Chikkamagaluru|Karnataka|Chikmagalur|
Madikeri|Karnataka|Coorg,Kodagu|
Karwar|Karnataka||
Bagalkot|Karnataka||
Gadag|Karnataka||
Koppal|Karnataka||
Ramanagara|Karnataka||
Thiruvananthapuram|Kerala|Trivandrum|TRV,TVC
Kochi|Kerala|Cochin,Ernakulam|COK,ERS,ERN
Kozhikode|Kerala|Calicut|CCJ,CLT
Thrissur|Kerala|Trichur|
Kannur|Kerala|Cannanore|CNN
Kollam|Kerala|Quilon|QLN
Alappuzha|Kerala|Alleppey|ALLP
Kottayam|Kerala||
Palakkad|Kerala|Palghat|PGT
Malappuram|Kerala||
Kasaragod|Kerala||
Pathanamthitta|Kerala||
Munnar|Kerala||
Thekkady|Kerala||
Wayanad|Kerala|Kalpetta|
Guruvayur|Kerala||
Varkala|Kerala||
Kovalam|Kerala||
Thalassery|Kerala|Tellicherry|
Tiruvalla|Kerala|Thiruvalla|
Aluva|Kerala|Alwaye|
Chennai|Tamil Nadu|Madras|MAA,MAS,MSB
Coimbatore|Tamil Nadu||CJB,CBE
Madurai|Tamil Nadu||IXM,MDU
Tiruchirappalli|Tamil Nadu|Trichy,Tiruchi|TRZ,TPJ
Salem|Tamil Nadu||SXV
Tirunelveli|Tamil Nadu||TEN
Thoothukudi|Tamil Nadu|Tuticorin|
Vellore|Tamil Nadu||
Erode|Tamil Nadu||
Tiruppur|Tamil Nadu|Tirupur|
Thanjavur|Tamil Nadu|Tanjore|
Kanchipuram|Tamil Nadu|Kanchi,Conjeevaram|
Hosur|Tamil Nadu||
Kanyakumari|Tamil Nadu|Cape Comorin|
Nagercoil|Tamil Nadu||
Ooty|Tamil Nadu|Udhagamandalam,Udagamandalam|
Kodaikanal|Tamil Nadu||
Dindigul|Tamil Nadu||
Karur|Tamil Nadu||
Kumbakonam|Tamil Nadu||
Rameswaram|Tamil Nadu||
Cuddalore|Tamil Nadu||
Nagapattinam|Tamil Nadu||
Pollachi|Tamil Nadu||
Sivakasi|Tamil Nadu||
Krishnagiri|Tamil Nadu||
Dharmapuri|Tamil Nadu||
Namakkal|Tamil Nadu||
Tiruvannamalai|Tamil Nadu||
Chengalpattu|Tamil Nadu|Chengalpet|
Puducherry|Puducherry|Pondicherry,Pondy|PNY,PDY
Karaikal|Puducherry||
Visakhapatnam|Andhra Pradesh|Vizag,Vishakhapatnam,Waltair|VTZ,VSKP
Vijayawada|Andhra Pradesh|Bezawada|VGA,BZA
Guntur|Andhra Pradesh||
Tirupati|Andhra Pradesh||TIR,TPTY
Nellore|Andhra Pradesh||
Kurnool|Andhra Pradesh||KJB
Kakinada|Andhra Pradesh||
Rajahmundry|Andhra Pradesh|Rajamahendravaram,Rajamundry|RJA
Kadapa|Andhra Pradesh|Cuddapah|CDP
Anantapur|Andhra Pradesh|Anantapuram|
Amaravati|Andhra Pradesh||
Eluru|Andhra Pradesh||
Ongole|Andhra Pradesh||
Srikakulam|Andhra Pradesh||
Vizianagaram|Andhra Pradesh||
Chittoor|Andhra Pradesh||
Machilipatnam|Andhra Pradesh||
Bhimavaram|Andhra Pradesh||
Tenali|Andhra Pradesh||
Proddatur|Andhra Pradesh||
Hindupur|Andhra Pradesh||
Puttaparthi|Andhra Pradesh||
Hyderabad|Telangana|Secunderabad,Cyberabad|HYD,HYB,KCG
Warangal|Telangana|Hanamkonda|
Karimnagar|Telangana||
Nizamabad|Telangana||
Khammam|Telangana||
Mahbubnagar|Telangana|Mahabubnagar|
Nalgonda|Telangana||
Adilabad|Telangana||
Siddipet|Telangana||
Ramagundam|Telangana||
Mancherial|Telangana||
Suryapet|Telangana||
Sangareddy|Telangana||
Bhubaneswar|Odisha|Bhubaneshwar|BBI,BBS
Cuttack|Odisha||CTC
Puri|Odisha||
Rourkela|Odisha|Raurkela|RRK,ROU
Sambalpur|Odisha||
Berhampur|Odisha|Brahmapur|BAM
Balasore|Odisha|Baleswar|
Jharsuguda|Odisha||JRG
Konark|Odisha||
Angul|Odisha||
Jajpur|Odisha||
Bhadrak|Odisha||
Baripada|Odisha||
Jeypore|Odisha||
Rayagada|Odisha||
Paradip|Odisha||
Talcher|Odisha||
Koraput|Odisha||
Kolkata|West Bengal|Calcutta|CCU,HWH,SDAH,KOAA
Howrah|West Bengal||
Siliguri|West Bengal|Bagdogra|IXB,NJP
Durgapur|West Bengal||RDP,DGR
Asansol|West Bengal||ASN
Darjeeling|West Bengal||
Kharagpur|West Bengal||KGP
Haldia|West Bengal||
Bardhaman|West Bengal|Burdwan|BWN
Malda|West Bengal|English Bazar|MLDT
Kalimpong|West Bengal||
Jalpaiguri|West Bengal||
Cooch Behar|West Bengal|Koch Bihar|
Digha|West Bengal||
Krishnanagar|West Bengal||
Bolpur|West Bengal|Shantiniketan,Santiniketan|
Bankura|West Bengal||
Purulia|West Bengal||
Barasat|West Bengal||
Patna|Bihar||PAT,PNBE
Gaya|Bihar||GAY
Bodh Gaya|Bihar|Bodhgaya|
Bhagalpur|Bihar||
Muzaffarpur|Bihar||
Darbhanga|Bihar||DBR
Purnia|Bihar|Purnea|
Begusarai|Bihar||
Arrah|Bihar||
Katihar|Bihar||
Munger|Bihar|Monghyr|
Chhapra|Bihar||
Sasaram|Bihar||
Hajipur|Bihar||
Motihari|Bihar||
Bettiah|Bihar||
Saharsa|Bihar||
Sitamarhi|Bihar||
Rajgir|Bihar||
Nalanda|Bihar||
Bihar Sharif|Bihar|Biharsharif|
Buxar|Bihar||
Siwan|Bihar||
Samastipur|Bihar||
Kishanganj|Bihar||
Ranchi|Jharkhand||IXR,RNC
Jamshedpur|Jharkhand|Tatanagar,Tata Nagar|IXW,TATA
Dhanbad|Jharkhand||DHN
Bokaro|Jharkhand|Bokaro Steel City|BKSC
Deoghar|Jharkhand||DGH
Hazaribagh|Jharkhand||
Giridih|Jharkhand||
Ramgarh|Jharkhand||
Dumka|Jharkhand||
Medininagar|Jharkhand|Daltonganj|
Chaibasa|Jharkhand||
Raipur|Chhattisgarh||RPR
Bilaspur|Chhattisgarh||PAB,BSP
Bhilai|Chhattisgarh||
Durg|Chhattisgarh||
Korba|Chhattisgarh||
Jagdalpur|Chhattisgarh||JGB
Raigarh|Chhattisgarh||
Ambikapur|Chhattisgarh||
Rajnandgaon|Chhattisgarh||
Dhamtari|Chhattisgarh||
Indore|Madhya Pradesh||IDR,INDB
Bhopal|Madhya Pradesh||BHO,BPL
Jabalpur|Madhya Pradesh||JLR,JBP
Gwalior|Madhya Pradesh||GWL
Ujjain|Madhya Pradesh||UJN
Sagar|Madhya Pradesh|Saugor|
Rewa|Madhya Pradesh||
Satna|Madhya Pradesh||
Ratlam|Madhya Pradesh||RTM
Dewas|Madhya Pradesh||
Khajuraho|Madhya Pradesh||HJR
Chhindwara|Madhya Pradesh||
Katni|Madhya Pradesh||
Singrauli|Madhya Pradesh||
Burhanpur|Madhya Pradesh||
Khandwa|Madhya Pradesh||
Morena|Madhya Pradesh||
Bhind|Madhya Pradesh||
Shivpuri|Madhya Pradesh||
Vidisha|Madhya Pradesh||
Guna|Madhya Pradesh||
Mandsaur|Madhya Pradesh||
Neemuch|Madhya Pradesh||
Itarsi|Madhya Pradesh||
Narmadapuram|Madhya Pradesh|Hoshangabad|
Pachmarhi|Madhya Pradesh||
Omkareshwar|Madhya Pradesh||
Maheshwar|Madhya Pradesh||
Orchha|Madhya Pradesh||
Sehore|Madhya Pradesh||
Betul|Madhya Pradesh||
Seoni|Madhya Pradesh||
Balaghat|Madhya Pradesh||
Mandla|Madhya Pradesh||
Guwahati|Assam|Gauhati|GAU,GHY
Dibrugarh|Assam||DIB
Jorhat|Assam||JRH
Silchar|Assam||IXS
Tezpur|Assam||TEZ
Tinsukia|Assam||
Nagaon|Assam||
Bongaigaon|Assam||
Kaziranga|Assam||
Shillong|Meghalaya||SHL
Imphal|Manipur||IMF
Agartala|Tripura||IXA
Aizawl|Mizoram||AJL
Kohima|Nagaland||
Dimapur|Nagaland||DMU
Itanagar|Arunachal Pradesh||HGI
Tawang|Arunachal Pradesh||
Gangtok|Sikkim||PYG
Namchi|Sikkim||
Sri Vijaya Puram|Andaman and Nicobar Islands|Port Blair|IXZ
Kavaratti|Lakshadweep||
''';
