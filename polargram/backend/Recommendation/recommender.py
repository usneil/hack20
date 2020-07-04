#Database
import firebase_admin
from firebase_admin import credentials, firestore

#Files
import json
from os import path

#Language
from nltk.corpus import wordnet

#Misc
import re

#Initialize
cred = credentials.Certificate(path.expanduser('Recommendation/Config/FireBaseConfig.json'))
firebase_admin.initialize_app(cred)
db = firestore.client()

#Get Data
class EditText():
    def __init__(self):
        #Creates a list of words that aren't keywords
        self.word_list = []
        with open('Recommendation/dontinclude.txt') as txt:
            for line in txt:
                self.word_list.append(line.strip('\n'))

    def check_words(self, check_list):
        #Removes words from list that isnt a keyword
        edits_list = check_list.copy()
        for word in check_list:
            if word in self.word_list:
                edits_list.remove(word)

        return edits_list

    def get_lowered_list(self, edit_list):
        #Returns a list of lowered list
        for item in edit_list:
            edit_list[edit_list.index(item)] = str(item).lower()
        return edit_list

    def no_special_text(self, text):
        #Returns a string with no special text
        text = re.sub("[^a-zA-Z0-9]+", "",text)
        return text

    def no_special_list_text(self, check_list):
        #Does the same thing as the function above, but enacts it throughout the entire list
        for obj in check_list:
            check_list[check_list.index(obj)] = self.no_special_text(obj)

        return check_list

    def find_intersections(self, list_one, list_two):
        #Find How Many Similar Objects two lists have
        return len(set(list_one) & set(list_two))

    def remove_duplicates(self, check_list):
        return list(set(check_list))

    def fix_list(self, check_list):
        #Combines all of the data and uses it on the list
        check_list = self.check_words(check_list)
        check_list = self.get_lowered_list(check_list)
        check_list = self.remove_duplicates(check_list)
        check_list = self.no_special_list_text(check_list)


        return check_list

    def fix_ai_words(self, word):
        final_list = []
        word = word.split('-')
        if len(word) > 1:
            for smaller_word in word:
                final_list.append(smaller_word)

        word = ''.join(word).split('_')
        if len(word) > 1:
            for smaller_word in word:
                final_list.append(smaller_word)

    def add_to_list(self, list_a, list_b):
        for obj in list_b:
            list_a.append(obj)

        return list_a



class GetData():
    def __init__(self):
        #Initialize the class
        self.db = firestore.client()
        self.editor = EditText()

    def get_user_posts(self):
        #Get all users' post
        users = {}

        for user in self.db.collection(u'users').stream():#Iterate over users
            posts = []
            for post in self.db.collection(u'users').document(user.id).collection('posts').stream():
                post_dict = post.to_dict()
                post_dict['name'] = post.id
                posts.append(post_dict)
                

            users[user.id] = posts
        return users

    def get_liked_posts(self, user):
        #Get Liked Post Data for a specific User
        user_liked_posts = []
        try:
            doc = self.db.collection(u'users').document(user).get().to_dict()
            liked_posts = doc['shaken_posts']
        

            for post in liked_posts:
                post_by = post.split('+')
                post_dict = {'UserID': post_by[0], 'PostID': post_by[1]}

                user_liked_posts.append(post_dict)
        except:
            #User Hasn't Ever Liked Posts
            pass

        return user_liked_posts

    
    def get_liked_post_data(self, user):
        #Gets the data from a user's liked post
        user_liked_words = []
        liked = self.get_liked_posts(user)

        for post in liked:
            doc = self.db.collection(u'users').document(post['UserID']).collection('posts').document(post['PostID']).get().to_dict()
            Title = str(doc['title']).split(' ')
            
            for Word in Title:
                user_liked_words.append(Word)
        keywords = self.editor.fix_list(user_liked_words)

        return {'Keywords': keywords}


    def get_similar_keywords(self, keywords_list):
        #Find Keywords that are similar to what the user likes
        synonyms = []
        for keyword in keywords_list:
            similar_sysnet = wordnet.synsets(keyword)
            for syn in similar_sysnet:
                for synonym in syn.lemmas():
                    synonyms.append(synonym.name().lower())



        for word in synonyms:         
            self.editor.fix_ai_words(word)
        synonyms = self.editor.fix_list(synonyms)

        keywords = self.editor.add_to_list(keywords_list, synonyms)
        return keywords


    def get_posts(self, keywords_list):
        list_of_posts = []

        List_Of_Users = self.get_user_posts()
        for user in List_Of_Users:

            user_posts = List_Of_Users[user]


            for posts in user_posts:
                title = posts['title']
                timestamp = posts['timestamp']
                post_id = posts['name']
                title = self.editor.fix_list(str(title).split(' '))
                
                if self.editor.find_intersections(keywords_list, title) >= 1:
                    post_data = {'userID': user, 'timestamp': timestamp, 'postID': post_id}
                    list_of_posts.append(post_data)

        return list_of_posts


def Get_Data(user):
    Data_Collections = GetData()
    keyword_list = Data_Collections.get_similar_keywords(Data_Collections.get_liked_post_data(user)['Keywords'])
    Posts = Data_Collections.get_posts(keyword_list)
    Posts_copy = Posts.copy()

    for post in Posts:
        if post['userID'] == user:
            Posts_copy.remove(post)

    return Posts_copy
    




    