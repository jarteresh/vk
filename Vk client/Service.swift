//
//  Service.swift
//  Vk client
//
//  Created by Ярослав on 29.01.2023.
//

import Foundation
import Alamofire
import RealmSwift

class Service {
    
    let baseUrl = "https://api.vk.com/method"
    let session = Session.instance
    let realm = try! Realm()
    
    func getFriends(completion: @escaping () -> Void)  {
        let url = baseUrl + "/friends.get"
        
        let param: Parameters = [
            "access_token": session.token,
            "v": "5.131",
            "user_id": session.userId,
            "order": "hints",
            "fields": "photo_100"
        ]
        AF.request(url, method: .get, parameters: param).responseData {response in
            
            guard let data = response.value else {return}
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let data = try decoder.decode(Users.self,from: data)
                self.saveUsers(users: data)
                completion()
            } catch {
                print(error)
            }
        }
    }
    
    func getPhotos(forUser userId: Int, completion: @escaping () -> Void){
        let url = baseUrl + "/photos.getAll"
        
        let param: Parameters = [
            "access_token": session.token,
            "v": "5.131",
            "owner_id": userId,
        ]
        AF.request(url, method: .get, parameters: param).responseData {response in
            guard let data = response.value else {return}
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let data = try decoder.decode(Photos.self,from: data)
                self.savePhotos(photos: data, ownerId: data.photos.first?.ownerId ?? 0)
                
                completion()
            } catch {
                print(error)
            }
        }
    }
    
    func getGroups(completion: @escaping () -> Void) {
        let url = baseUrl + "/groups.get"
        
        let param: Parameters = [
            "access_token": session.token,
            "v": "5.131",
            "user_id": session.userId,
            "extended": 1
        ]
        AF.request(url, method: .get, parameters: param).responseData {response in
            guard let data = response.value else {return}
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let data = try decoder.decode(Groups.self,from: data)
                self.saveGroups(groups: data)
                completion()
            } catch {
                print(error)
            }
        }
    }
    
    func getGroupsBySearch(forName name: String, completion: @escaping (Groups) -> Void) {
        let url = baseUrl + "/groups.search"
        
        let param: Parameters = [
            "access_token": session.token,
            "v": "5.131",
            "q": name,
            "count": 100
        ]
        AF.request(url, method: .get, parameters: param).responseData {response in
            guard let data = response.value else {return}
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let data = try decoder.decode(Groups.self,from: data)
                completion(data)
            } catch {
                print(error)
            }
        }
    }
    
    func getPhoto(fromUrl urlString: String, completion: @escaping (UIImage) -> Void) {
        let url = URL(string: urlString)
        URLSession.shared.dataTask(with: url!) { (data, response, error) in
            completion(UIImage(data: data ?? Data()) ?? UIImage())
        }.resume()
    }
    
    func saveUsers(users: Users) {
        let allUsers = realm.objects(RealmUsers.self)
        let allUser = realm.objects(RealmUser.self)
        let realmUsers = convertToRealmUsers(from: users)
        do {
            if allUsers.isEmpty {
                try realm.write {
                    realm.add(realmUsers)
                }
            } else {
                try realm.write {
                    realm.delete(allUsers)
                    realm.delete(allUser)
                    realm.add(realmUsers)
                }
            }
        } catch {
            print(error)
        }
    }

    func saveGroups(groups: Groups) {
        let allGroups = realm.objects(RealmGroups.self)
        let allGroup = realm.objects(RealmGroup.self)
        let realmGroups = convertToRealmGroups(from: groups)
        do {
            if allGroups.isEmpty {
                try realm.write {
                    realm.add(realmGroups)
                }
            } else {
                try realm.write {
                    realm.delete(allGroups)
                    realm.delete(allGroup)
                    realm.add(realmGroups)
                }
            }
        } catch {
            print(error)
        }
    }

    func savePhotos(photos: Photos, ownerId: Int) {
        let allPhoto = realm.objects(RealmPhoto.self).filter {
            $0.ownerId == ownerId
        }
        let allPhotos = realm.objects(RealmPhotos.self).filter {
            $0.photos.first?.ownerId == ownerId
        }
        let realmPhotos = convertToRealmPhotos(from: photos)
        do {
            try realm.write {
                realm.delete(allPhotos)
                realm.delete(allPhoto)
                realm.add(realmPhotos)
            }
        } catch {
            print(error)
        }
    }

    func convertToRealmUsers(from users: Users) -> RealmUsers {
        let realmUsers = RealmUsers()
        realmUsers.count = users.count
        for user in users.users {
            let realmUser = RealmUser()
            realmUser.id = user.id
            realmUser.firstName = user.firstName
            realmUser.lastName = user.lastName
            realmUser.avatar = user.avatar
            realmUsers.users.append(realmUser)
            
        }
        return realmUsers
    }
    
    func convertToRealmGroups(from groups: Groups) -> RealmGroups {
        let realmGroups = RealmGroups()
        realmGroups.count = groups.count
        for group in groups.groups {
            let realmGroup = RealmGroup()
            realmGroup.id = group.id
            realmGroup.name = group.name
            realmGroup.avatar = group.avatar
            realmGroups.groups.append(realmGroup)
        }
        return realmGroups
    }
    
    func convertToRealmPhotos(from photos: Photos) -> RealmPhotos {
        let realmPhotos = RealmPhotos()
        realmPhotos.count = photos.count
        for photo in photos.photos {
            let realmPhoto = RealmPhoto()
            realmPhoto.albumId = photo.albumId
            realmPhoto.date = photo.date
            realmPhoto.id = photo.id
            realmPhoto.ownerId = photo.ownerId
            realmPhoto.height = photo.height
            realmPhoto.width = photo.width
            realmPhoto.url = photo.url
            realmPhotos.photos.append(realmPhoto)
        }
        return realmPhotos
    }
}
