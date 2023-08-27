import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'firebase_options.dart';
import 'package:get/get.dart';
import 'package:firebase_database/firebase_database.dart';

var user;
var uid;

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
var logger = Logger(
  printer: PrettyPrinter(),
);

Future<void> signInWithAnonymous() async {
  UserCredential _credential = await _firebaseAuth.signInAnonymously();
  if (_credential.user != null) {
    logger.e(_credential.user!.uid);
    Get.to(MyImageUploader());
  }
}

Future<void> createEmailAndPassword(String em, String pw) async {
  try {
    UserCredential _credential =
    await _firebaseAuth.createUserWithEmailAndPassword(
        email: em, password: pw);
    if (_credential.user != null) {
      user = _credential.user;
    } else {
      print('Server Error');
    }
  } on FirebaseAuthException catch (error) {
    logger.e(error.code);
    String? _errorCode;
    switch (error.code) {
      case "email-already-in-use":
        _errorCode = error.code;
        break;
      case "invalid-email":
        _errorCode = error.code;
        break;
      case "weak-password":
        _errorCode = error.code;
        break;
      case "operation-not-allowed":
        _errorCode = error.code;
        break;
      default:
        _errorCode = null;
    }
    if (_errorCode != null) {
      print(_errorCode);
    }
  }
}

Future<void> SignWithEmail(String em, String pw) async {
  try {
    UserCredential _credential =
    await _firebaseAuth.signInWithEmailAndPassword(
        email: em, password: pw);
    if (_credential.user != null) {
      user = _credential.user;
      uid = _credential.user!.uid;
      print(uid);
      Get.to(MyImageUploader());
    } else {
      print('Server Error');
    }
  } on FirebaseAuthException catch (error) {
    logger.e(error.code);
    String? _errorCode;
    switch (error.code) {
      case "invalid-email":
        _errorCode = error.code;
        break;
      case "user-disabled":
        _errorCode = error.code;
        break;
      case "user-not-found":
        _errorCode = error.code;
        break;
      case "wrong-password":
        _errorCode = error.code;
        break;
      default:
        _errorCode = null;
    }
    if (_errorCode != null) {
      print(_errorCode);
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'lastduri',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController(); //입력되는 값을 제어
  final TextEditingController _passwordController = TextEditingController();

  Widget _userIdWidget(){
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '이메일',
      ),
      validator: (String? value){
        if (value!.isEmpty) {// == null or isEmpty
          return '이메일을 입력해주세요.';
        }
        return null;
      },
    );
  }

  Widget _passwordWidget(){
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: '비밀번호',
      ),
      validator: (String? value){
        if (value!.isEmpty) {// == null or isEmpty
          return '비밀번호를 입력해주세요.';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _userIdWidget(),
                const SizedBox(height: 20.0),
                _passwordWidget(),
                const SizedBox(height: 20.0,),
                ElevatedButton(onPressed: signInWithAnonymous, child: Text('signInWithAnonymous')),
                ElevatedButton(onPressed: () async{
                  await createEmailAndPassword(_emailController.text, _passwordController.text);}, child: Text('signIn')),
                ElevatedButton(onPressed: () async{
                  await SignWithEmail(_emailController.text, _passwordController.text);}, child: Text('LogIn')),
              ],
            )
        )
    );;
  }
}


class MyImageUploader extends StatefulWidget {
  @override
  _MyImageUploaderState createState() => _MyImageUploaderState();
}

class _MyImageUploaderState extends State<MyImageUploader> {
  File? _imageFile;
  final picker = ImagePicker();

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      // 이미지 파일이 없는 경우 아무 작업도 수행하지 않음
      return;
    }

    try {
      // Firebase Storage에 접근하기 위해 FirebaseStorage 인스턴스를 생성
      FirebaseStorage storage = FirebaseStorage.instance;

      // 이미지 파일 이름으로 현재 시간을 사용
      String imageName = DateTime.now().toString();

      // "images"라는 폴더에 이미지를 업로드
      Reference ref = storage.ref().child('images/$imageName');

      // putFile 메서드를 사용하여 이미지를 업로드
      await ref.putFile(_imageFile!);

      // 업로드가 성공하면 다운로드 URL 얻어오기
      String downloadURL = await ref.getDownloadURL();

      //----------------------여기서 downloadURL을 Firebase Database에 업로드해야함--------------------------------------
      FirebaseDatabase _realtime = FirebaseDatabase.instance;
      await _realtime.ref("users")
      .child(uid)
      .set(_TestModel(uid, downloadURL).toJson());

      // 업로드가 완료되면 상태를 업데이트하여 이미지를 보여줌
      setState(() {
        _imageFile = null; // 이미지 업로드 후, 이미지 파일을 초기화
      });

      // 업로드가 성공했다는 메시지를 보여줄 수 있음
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('이미지 업로드 성공'),
          content: Text('이미지가 성공적으로 업로드되었습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      // 업로드가 실패하면 오류 메시지를 출력
      print('이미지 업로드 오류: $e');
    }
  }

  Future<void> _pickImage() async {
    // 갤러리에서 이미지를 선택
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      // 선택한 이미지 파일을 상태에 저장
      if (pickedFile != null) {
        _imageFile = File(pickedFile.path);
      } else {
        print('이미지 선택 취소');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 업로더'),
      ),
      body: Center(
        //imageFile이 null일 경우 이미지를 선택해달라고 출력(잘 올라갔나 확인용)
        child: _imageFile == null
            ? Text('이미지를 선택해주세요.')
            : Image.file(_imageFile!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _pickImage(); // 갤러리에서 이미지를 선택
          _uploadImage();// 선택한 이미지를 Firebase Storage에 업로드
        },
        tooltip: '이미지 선택',
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}

//Json 파싱이 가능하도록 만든 데이터 모델
class _TestModel{
  final String uid;
  final String downloadURL;

  _TestModel(this.uid, this.downloadURL);

  Map<String, dynamic> toJson(){
    return {
      "uid" : uid,
      "downloadURL" : downloadURL,
    };
  }
}
//cloud_firestore를 import한 후 Timestamp 객체를 사용하는 시도 필요
//https://github.com/MiDoRe2/chatting_app/blob/master/lib/model/message_model.dart 참고