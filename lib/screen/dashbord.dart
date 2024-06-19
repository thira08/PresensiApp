import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_application_2/model/presensi.dart';
import 'package:flutter_application_2/screen/rekap_screen.dart';
import 'package:flutter_application_2/utils/mix.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String nik = "", token = "", name = "", dept = "", imgUrl = "";
  bool isMasuk = true;

  Future<void> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    String? nik = prefs.getString('nik') ?? "";
    String? token = prefs.getString('jwt') ?? "";
    String? name = prefs.getString('name') ?? "";
    String? dept = prefs.getString('dept') ?? "";
    String? imgUrl = prefs.getString('imgProfil') ?? "not found";

    setState(() {
      this.nik = nik;
      this.token = token;
      this.name = name;
      this.dept = dept;
      this.imgUrl = imgUrl;
    });
  }

  Future<Presensi> fetchPresensi(String nik, String tanggal) async {
    String url =
        'https://presensi.spilme.id/presence?nik=$nik&tanggal=$tanggal';
    final response = await http
        .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      return Presensi.fromJson(jsonDecode(response.body));
    } else {
      return Presensi(
        id: 0,
        nik: this.nik,
        tanggal: getTodayDate(),
        jamMasuk: "--:--",
        jamKeluar: '--:--',
        lokasiMasuk: '-',
        lokasiKeluar: '-',
        status: '-',
      );
    }
  }

  Future<void> saveStatusMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isMasuk', isMasuk);
  }

  Future<void> loadStatusMasuk() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isMasuk = prefs.getBool('isMasuk') ?? true;
    });
  }

  Future<void> recordAttendance() async {
    Navigator.pop(context);
    //end point
    const String endpointMasuk = 'https://presensi.spilme.id/entry';
    const String endpointKeluar = 'https://presensi.spilme.id/exit';

    final endpoint = isMasuk ? endpointMasuk : endpointKeluar;
    final requestBody = isMasuk
        ? {
            'nik': nik,
            'tanggal': getTodayDate(),
            'jam_masuk': getTime(),
            'lokasi_masuk': 'polbeng',
          }
        : {
            'nik': nik,
            'tanggal': getTodayDate(),
            'jam_keluar': getTime(),
            'lokasi_keluar': 'polbeng',
          };

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(responseBody['message'])),
      );
      setState(() {
        isMasuk = !isMasuk;
        saveStatusMasuk(); // simpan status absensi
      });
      //refresh informasi absensi
      fetchPresensi(nik, getTodayDate());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record attendance')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
    loadStatusMasuk();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(
              height: 24,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child:
                          Image.network(imgUrl, height: 84, fit: BoxFit.cover)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        textAlign: TextAlign.left,
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          color: const Color(0xFF263238),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        dept,
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          color: const Color(0xFF263238),
                        ),
                      ),
                    ],
                  )
                ]),
                Stack(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none),
                      iconSize: 32,
                      color: Colors.black,
                    ),
                    Positioned(
                      right: 10,
                      top: 8,
                      child: Container(
                          height: 15,
                          width: 15,
                          decoration: BoxDecoration(
                              color: const Color(0xFFEF6497),
                              borderRadius: BorderRadius.circular(15 / 2)),
                          child: Center(
                              child: Text(
                            "2",
                            style: GoogleFonts.mPlus1p(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ))),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kehadiran hari ini',
                  style: GoogleFonts.manrope(
                      fontSize: 16,
                      color: const Color(0xFF101317),
                      fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecapScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Rekap Absensi',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: const Color(0xFF12A3DA),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            FutureBuilder<Presensi>(
              future: fetchPresensi(nik, getTodayDate()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  final data = snapshot.data;
                  return Row(
                    children: [
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                                color: Color.fromARGB(255, 219, 226, 228),
                                width: 1.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              35, 48, 134, 254),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: SvgPicture.asset(
                                          'assets/images/login.svg'),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Masuk',
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        color: const Color(0xFF101317),
                                      ),
                                      textAlign: TextAlign.left,
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  data?.jamMasuk ?? '--:--',
                                  style: GoogleFonts.lexend(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF101317),
                                  ),
                                ),
                                Text(
                                  getPresenceEntryStatus(data?.jamMasuk ?? '-'),
                                  style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    color: const Color(0xFF101317),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Card(
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                                color: Color.fromARGB(255, 219, 226, 228),
                                width: 1.0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                          color: const Color.fromARGB(
                                              35, 48, 134, 254),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: SvgPicture.asset(
                                        'assets/images/logout.svg',
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Keluar',
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        color: const Color(0xFF101317),
                                      ),
                                      textAlign: TextAlign.left,
                                    )
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  data?.jamKeluar ?? '--:--',
                                  style: GoogleFonts.lexend(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF101317),
                                  ),
                                ),
                                Text(
                                  getPresenceExitStatus(data?.jamKeluar ?? '-'),
                                  style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    color: const Color(0xFF101317),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Center(child: Text('No data available'));
                }
              },
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) {
                    return attandanceScreen();
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF12A3DA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  )),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.circle_outlined,
                    color: Colors.white,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 5),
                  Text(
                    'Tekan untuk presensi ${isMasuk ? 'masuk' : 'pulang'}',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: 150,
                  height: 190,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black,
                          Colors.grey,
                          Colors.grey,
                          Colors.grey,
                          Colors.black,
                        ],
                      )),
                  child: Padding(
                    padding: EdgeInsets.all(13.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              "Izin Absen",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Isi form untuk meminta izin absen",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 120,
                              child: Column(
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {},
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          "Ajukan Izin",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 150,
                  height: 190,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple,
                          Colors.purpleAccent,
                          Colors.purpleAccent,
                          Colors.purpleAccent,
                          Colors.purple,
                        ],
                      )),
                  child: Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              "Ajukan Cuti",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    "Isi form untuk mengajukan cuti",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              width: 120,
                              child: Column(
                                children: <Widget>[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {},
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          "Ajukan Cuti",
                                          style: TextStyle(
                                              color: Colors.purple,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      )),
    );
  }

  Widget attandanceScreen() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Presensi ${isMasuk ? 'Masuk' : 'Pulang'}',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                const Icon(
                  Icons.calendar_month,
                  color: Color(0xffE74C3C),
                  size: 32,
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tanggal ${isMasuk ? 'Masuk' : 'Pulang'}',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff111111),
                        )),
                    Text(getToday(),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xff707070),
                        )),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              children: [
                const Icon(
                  Icons.av_timer_outlined,
                  color: Color(0xffE74C3C),
                  size: 32,
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jam ${isMasuk ? 'Masuk' : 'Pulang'}',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff111111),
                        )),
                    Text(getTime(),
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xff707070),
                        )),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 40,
            ),
            Text(
              'Foto selfie di area kantor',
              style: GoogleFonts.manrope(
                fontSize: 16,
                color: const Color(0xff707070),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Container(
                height: 200, // Set your desired height
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Ambil Gambar'),
                  onPressed: () {
                    // Implement your image picking logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: recordAttendance,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Simpan',
                style: GoogleFonts.manrope(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}
