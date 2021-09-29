import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class Chat extends StatefulWidget {

  @override
  _ChatState createState() => _ChatState();
}

class _ChatState extends State<Chat> {

  final sent = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();
  TextEditingController msgSent = TextEditingController();

  final fireStore = Firebase.initializeApp();
  final _mFirestore = FirebaseFirestore.instance;
  var storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool me = true;
  bool isImage = false;
  @override
  void initState() {
    super.initState();
    print(DateTime.now());
  }

  sentMessage(String msg,bool isMe) async{
    fireStore.then((value) async {
      FirebaseFirestore.instance.
      collection("message").doc(DateTime.now().toString()).set({
        "time": DateTime.now(),
        "me": isMe,
        "msg": isImage == false ?
        msg.toString() : "",
        "isImage": isImage,
        "imgUrl": isImage == false ? "" : imageUrl,
      });
    }).whenComplete(() {
      setState(() {
        msgSent.clear();
        imageUrl = "";
        // _scrollController.animateTo(
        //     _scrollController.position.maxScrollExtent,
        //     duration: Duration(milliseconds: 200),
        //     curve: Curves.easeInOut
        // );
        FocusScope.of(context).unfocus();
      });
    });
  }

  // late File image;
  // uploadPic() async {
  //
  //    image = (await _picker.pickImage(source: ImageSource.gallery)) as File;
  //
  //    var ref =  storage
  //        .ref()
  //        .child('playground')
  //        .child('/some-image.jpg');
  //
  //    final uploadTask = ref.putFile(image);
  //
  //    Uri location = (await uploadTask.future).downloadUrl;
  //   //returns the download url
  //   // return location;
  // }

  String imageUrl = "";

  uploadImage() async {
    final _firebaseStorage = FirebaseStorage.instance;
    XFile? image;
    //Check Permissions
    await Permission.photos.request();

    var permissionStatus = await Permission.photos.status;

    if (permissionStatus.isGranted){
      //Select Image
      image = await _picker.pickImage(source: ImageSource.gallery);
      var file = File(image!.path);

        //Upload to Firebase
        var snapshot = await _firebaseStorage.ref()
            .child('images/imageName')
            .putFile(file);
        var downloadUrl = await snapshot.ref.getDownloadURL();
        setState(() {
          imageUrl = downloadUrl;
          isImage = true;
        });

      sentMessage(imageUrl,me);

    } else {
      print('Permission not granted. Try Again with permission access');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("chat nhi chaitai"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.lightBlueAccent,
        leading: GestureDetector(
          onTap: (){
            setState(() {
              me = true;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 5),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: me == true ? Colors.blue.shade700 : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: Text("ME"),
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: (){
              setState(() {
                me = false;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5,vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: me == false ? Colors.blue.shade700 : Colors.transparent,
                ),
                width: 80,
                alignment: Alignment.center,
                child: Text("FRIEND"),
              ),
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: StreamBuilder<QuerySnapshot>(
              stream: _mFirestore.collection("message").snapshots(),
              builder: (context, snapshot) {
                if(!snapshot.hasData){
                  return Center(
                    child: Text("Loading..."),
                  );
                }else{
                  // final messages = snapshot.data!.docs.elementAt(2)["name"];
                  return SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    controller: _scrollController,
                    child: Column(
                      children: [
                        ListView.builder(
                          itemCount: snapshot.data!.size,
                          shrinkWrap: true,
                          scrollDirection: Axis.vertical,
                          physics: NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            bool isMe = snapshot.data!.docs.elementAt(index)["me"];
                            bool img =  snapshot.data!.docs.elementAt(index)["isImage"];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Material(
                                    borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(30.0), bottomLeft: Radius.circular(30.0),bottomRight: Radius.circular(30.0)):BorderRadius.only(topLeft: Radius.circular(30.0), topRight: Radius.circular(30.0),bottomRight: Radius.circular(30.0)),
                                    elevation: 5.0,
                                    color: isMe ? Colors.lightBlueAccent: Colors.white,
                                    child: img == false ?
                                    Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                      child: Text(
                                        snapshot.data!.docs.elementAt(index)["msg"],
                                        style: TextStyle(
                                          color: isMe ? Colors.white: Colors.lightBlueAccent,
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ) : Image.network(
                                      snapshot.data!.docs.elementAt(index)["imgUrl"],
                                      fit: BoxFit.contain,),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 70,),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width,
              color: Colors.transparent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      height: 45,
                      width: MediaQuery.of(context).size.width*0.8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.lightBlueAccent),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10,bottom: 3),
                        child: TextFormField(
                          keyboardType: TextInputType.multiline,
                          key: sent,
                          controller: msgSent,
                          cursorColor: Colors.lightBlueAccent,
                          maxLength: null,
                          maxLines: null,
                          cursorHeight: 20,
                          decoration: InputDecoration(
                            hintText: " Type your message",
                            hintStyle: TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 16,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: GestureDetector(
                                onTap: (){
                                  uploadImage();
                                },
                                child: Container(
                                    height: 45,
                                    width: 45,
                                    child: Icon(Icons.attach_file,color: Colors.lightBlueAccent,)),
                              ),
                            ),
                            contentPadding: EdgeInsets.fromLTRB(0.0, 7.0, 20.0, 10.0),
                            focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent)
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      setState(() {
                        isImage = false;
                      });
                      sentMessage(msgSent.text,me);
                    },
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: Colors.lightBlueAccent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.send,color: Colors.white,size: 20,),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
