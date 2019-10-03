


//Firebase Server-Side Code for Pictomap

const functions = require('firebase-functions'); //Initialize Firebase Functions
const admin = require('firebase-admin'); //Initialize Firebase Admin
admin.initializeApp(functions.config().firebase); //Initialize App with Admin SDK and Firebase Functions
const db = admin.firestore();
const defaultStorage = admin.storage();








//WORKS

exports.followUser = functions.firestore.document('/Users/{uid}/Following/{follow_uid}') //Trigger fired when a new {Following} child is added to a user
.onCreate((snapshot, context) => {
          
    const uid1 = context.params.follow_uid; //The user that was followed
    const uid  = context.params.uid; //The user that followed
          
    return admin.firestore().collection('Users/' + uid1 + '/Followers/').doc(uid).set({"UID": uid}).then(function() { //Add child under followed user's {Followers} node
        return console.log("Follower Updated.");  //Success
    }).catch(function(error){
		console.log("Follower Update Failed."); //Error
        return admin.firestore().collection('Users/' + uid + '/Following/').doc(uid1).delete();
	});
});









//WORKS

exports.unfollowUser = functions.firestore.document('/Users/{uid}/Following/{follow_uid}') //Trigger fired when an existing {Following} child is removed from a user
.onDelete((snapshot, context) => {
          
    const uid1 = context.params.follow_uid; //The user that was unfollowed
    const uid  = context.params.uid; //The user that unfollowed
          
    return admin.firestore().collection('Users/' + uid1 + '/Followers/').doc(uid).delete().then(function() {  //Delete child under unfollowed user's {Followers} node
		return console.log("Follower Updated."); //Success
	}).catch(function(error){
		console.log("Follower Update Failed."); //Error
        return admin.firestore().collection('Users/' + uid + '/Following/').doc(uid1).set({"UID": uid1});
	});
});









//ONLY DELETES USER DOC, NOT SUBCOLLECTIONS OR THEIR DOCS

exports.deleteUser = functions.auth.user() //Trigger fired when a user deletes their account
.onDelete((user) => {
          
    const uid = user.uid; //The User that deleted their account
          
    return admin.firestore.collection('Users/').doc(uid).delete(); //Delete the deleted user's node from the Firebase Database
});









//WORKS

exports.deleteFromFriendFollowingList = functions.firestore.document('/Users/{uid}/Followers/{follow_uid}') //Trigger fired when user is removed from Firebase Database
.onDelete((snapshot, context) => {
          
    const uid1 = context.params.follow_uid; //The user(s) who hold the deleted user's child name in their {Following} node
    const uid  = context.params.uid; //The user who's account was removed
          
    return admin.firestore().collection('Users/' + uid1 + '/Following/').doc(uid).delete().then(function(){ //Remove deleted user's child from {Following} node
        return console.log("Follower Updated."); //Success
    }).catch(function(error){
        return console.log("Follower Update Failed."); //Error
    });
});









//WORKS

exports.updateLatestPost = functions.firestore.document('Users/{uid}/Posts/{postID}')
.onCreate((snapshot, context) => {
          
    const id = context.params.postID;
    const uid = context.params.uid;
    const date = snapshot.data().Timestamp;
          
    // Update Newest Post
    return admin.firestore().collection('Users/').doc(uid).update({Latest : date}).then(function(){
        return console.log("Follower Updated."); //Success
    }).catch(function(error){
        return console.log("Follower Update Failed."); //Error
    });
});











exports.removeCommentPicFromStorage = functions.firestore.document('Users/{uid}/Posts/{postID}/Comments/{commentID}')
.onDelete((snapshot, context) => {
          
    const id = context.params.postID;
    const uid = context.params.uid;
    const l = snapshot.data().PhotoUID;
          
    if (snapshot.data().isPic === true){
        console.log(l);
        const bucket = defaultStorage.bucket();
        const file = bucket.file(uid + '/Comment-' + l + '.png');
        // Delete the file
          
        // * //
        return file.delete().then(function(){ //Remove deleted comment photo from storage bucket
            return console.log("Removed Comment Photo."); //Success
        }).catch(function(error){
            return console.log(error); //Error
        });
    }
    else{
        console.log("NOT PIC COMMENT")
        return 0
          
    }
});









exports.removeOldProfilePicFromStorage = functions.firestore.document('Users/{uid}')
.onUpdate((change, context) => {
          
    const oldProfileUpdate = change.before.data();
    const uid = change.after.id;
    const oldDP = oldProfileUpdate.ProfilePictureUID;
    const newDP = change.after.data().ProfilePictureUID;
          
    if(newDP !== oldDP){
        console.log(uid);
        const bucket = defaultStorage.bucket();
        const file = bucket.file(uid + '/profile_pic-' + oldDP + '.png');
        // Delete the file
        return file.delete().then(function(){ //Remove deleted profile photo from storage bucket
            return console.log("Removed Old Profile Photo."); //Success
        }).catch(function(error){
            return console.log(error); //Error
        });
    }
    else{
        console.log("SAME PROFILE PIC")
        return 0
    }
});








exports.deleteFaultyCommentFromPost = functions.https.onCall((data, context) => {
                
    const accountUID = data.postOwnerUID;
    const commentID = data.commentID;
    const postID = data.postID;

    return admin.firestore().collection('Users/' + accountUID  + '/Posts/' + postID + '/Comments').doc(commentID).delete().then(function(){
        return console.log("Faulty Comment Delete Success"); //Success
    }).catch(function(error){
        return console.log("Faulty Comment Delete Failure"); //Error
    });
});
