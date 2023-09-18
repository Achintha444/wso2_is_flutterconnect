import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:wso2_is_flutterconnect/ui_util.dart';

const FlutterAppAuth flutterAppAuth = FlutterAppAuth();

const String clientId = '<client-id>';
const String redirectUrl = 'wso2is.sampleflutterapp://login-callback';
const String discoveryUrl = 'https://localhost:9443/oauth2/token/.well-known/openid-configuration';
Uri userInfoEndpoint = Uri.parse('https://localhost:9443/oauth2/userinfo');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  late int _pageIndex;
  late bool _isUserLoggedIn;
  late String? _idToken;
  late String? _accessToken;
  late String? _firstName;
  late String? _lastName;
  late String? _dateOfBirth;
  late String? _country;
  late String? _mobile;
  late String? _photo;

  @override
  void initState() {
    super.initState();
    _pageIndex = 1;
    _isUserLoggedIn = false;
    _idToken = '';
    _accessToken = '';
    _firstName = '';
    _lastName = '';
    _dateOfBirth = '';
    _country = '';
    _mobile = '';
    _photo = '';
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asgardeo Flutter Integration',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange.shade400,
          title: Column(
            children: [
              SvgPicture.asset(
                'assets/images/logo.svg',
                width: 200,
              ),
              const SizedBox(height: 10),
              const Text(
                'WSO2 Identity Server Connect Example',
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
        body: Container(
          width: UiUtil.getMediaQueryWidth(context),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1, 1),
              colors: [
                Colors.orange,
                Colors.orange.withOpacity(0),
              ],
              tileMode: TileMode.clamp,
              radius: 1,
            ),
          ),
          child: _isUserLoggedIn
              ? _pageIndex == 2
                  ? HomePage(retrieveUserDetails, logOutFunction)
                  : _pageIndex == 3
                      ? ProfilePage(_firstName, _lastName, _dateOfBirth,
                          _country, _mobile, _photo, setPageIndex)
                      : LogInPage(loginFunction)
              : LogInPage(loginFunction),
        ),
      ),
    );
  }

  void setPageIndex(index) {
    setState(() {
      _pageIndex = index;
    });
  }

  Future<void> loginFunction() async {
    try {
      final AuthorizationTokenResponse? result =
          await flutterAppAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          discoveryUrl: discoveryUrl,
          scopes: ['openid', 'profile', 'address', 'phone'],
        ),
      );

      setState(() {
        _isUserLoggedIn = true;
        _idToken = result?.idToken;
        _accessToken = result?.accessToken;
        _pageIndex = 2;
      });

    } catch (e, s) {
      print('Error while login to the system: $e - stack: $s');
      setState(() {
        _isUserLoggedIn = false;
      });
    }
  }

  Future<void> retrieveUserDetails() async {
    final userInfoResponse = await http.get(
      userInfoEndpoint,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (userInfoResponse.statusCode == 200) {
      var profile = jsonDecode(userInfoResponse.body);
      setState(() {
        _firstName = profile['given_name'];
        _lastName = profile['family_name'];
        _dateOfBirth = profile['birthdate'];
        _country = profile['address']['country'];
        _mobile = profile['phone_number'];
        _photo = profile['picture'];
        _pageIndex = 3;
      });
    } else {
      throw Exception('Failed to get user profile information');
    }
  }

  void logOutFunction() async {
    try {
      await flutterAppAuth.endSession(
        EndSessionRequest(
          idTokenHint: _idToken,
          postLogoutRedirectUrl: redirectUrl,
          discoveryUrl: discoveryUrl,
        ),
      );

      setState(() {
        _isUserLoggedIn = false;
        _pageIndex = 1;
      });
    } catch (e, s) {
      print('Error while logout from the system: $e - stack: $s');
    }
  }
}

class LogInPage extends StatelessWidget {
  final Function loginFunction;

  const LogInPage(this.loginFunction, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.orange),
        ),
        onPressed: () async {
          await loginFunction();
        },
        child: const Text('Sign In'),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final Function retriveProfileFunction;
  final Function logOutFunction;

  const HomePage(this.retriveProfileFunction, this.logOutFunction, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Welcome!', style: TextStyle(fontSize: 35)),
          const SizedBox(height: 100),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.orange),
            ),
            onPressed: () async {
              await retriveProfileFunction();
            },
            child: const Text('View Profile'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            onPressed: () async {
              await logOutFunction();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String? firstName;
  final String? lastName;
  final String? dateOdBirth;
  final String? country;
  final String? mobile;
  final String? photo;
  final Function setPageIndex;

  const ProfilePage(this.firstName, this.lastName, this.dateOdBirth,
      this.country, this.mobile, this.photo, this.setPageIndex,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Profile Information', style: TextStyle(fontSize: 30)),
          const SizedBox(height: 50),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.orange, width: 4.0),
              shape: BoxShape.circle,
              image: DecorationImage(
                fit: BoxFit.fill,
                image: NetworkImage(photo!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text('First Name: ${firstName!}', style: const TextStyle(fontSize: 20)),
                  Text('Last Name: ${lastName!}', style: const TextStyle(fontSize: 20)),
                  Text('Date Of Birth: ${dateOdBirth!}', style: const TextStyle(fontSize: 20)),
                  Text('Mobile: ${mobile!}', style: const TextStyle(fontSize: 20)),
                  Text('Country: ${country!}', style: const TextStyle(fontSize: 20)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.orange),
            ),
            onPressed: () {
              setPageIndex(2);
            },
            child: const Text('Back to home'),
          ),
        ],
      ),
    );
  }
}
