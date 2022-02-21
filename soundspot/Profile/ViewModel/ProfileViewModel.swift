//
//  ProfileViewModel.swift
//  soundspot
//
//  Updated by Yassine Regragui on 2/20/22.
//

import Foundation
import SwiftUI
import Combine

class ProfileViewModel: ObservableObject{
    init(){
        getUserProfile()
    }
    @Published var profile: ProfileModel? = nil
    @Published var showFilePicker = false
    @Published var clickedTrack :Int? = nil
    @State var tracksList = Array<MusicModel>()
    @Published var uploadingFile = false
    @Published var uploadProgress : Double = 0.0
    private var localString = ""
    private var profileRepo = ProfileRepository()
    private var profileFirstLoad = true
    
    
    func onEvent(event : ProfileEvents){
        switch(event){
        case .ProfileViewLoaded:
            // the profile is loaded on the init function,
            // and ProfileViewLoad gets called again when the views are loaded
            // Updates the profile only when coming back from the music player
            if(!profileFirstLoad){
                getUserProfile()
            }else{
                profileFirstLoad = false
            }
        }
    }
    
    private func getUserProfile(){
        profileRepo.getUserProfile{ result in
            DispatchQueue.main.async {
                switch result{
                case .success(let savedProfile):
                    self.profile = savedProfile
                    print("Got user profile, list count \(savedProfile.singlesList?.count ?? 0)")
                    self.getPictures()
                case .failure(_):
                    self.showErrorLoadingProfile()
                }
            }
        }
    }
    
    
    private func getPictures(){
        print("Getting pictures")
        for (index, _) in profile!.singlesList!.enumerated(){
            if(profile?.singlesList![index].pictureLink != nil){
                profileRepo.getTrackPicture(url: URL(string: (profile?.singlesList![index].pictureLink)!)!) { result in
                    switch result{
                    case .success(let data):
                        self.profile?.singlesList?[index].pictureData = data
                        self.profile?.singlesList![index].pictureDownloaded = true
                    case .failure(_):
                        print("Failed to get picture of track ")
                    }
                }
            }
        }
    }
    
    private func showErrorLoadingProfile(){
        
    }
    
    
    private func launchPlayer(index: Int){
        @State var isActive = true
        _ = NavigationLink(self.localString, destination: PlayerView(viewModel: PlayerViewModel(trackList: (self.profile?.singlesList!)!, trackIndex: index)), isActive: $isActive)
    }
    
    
    func showDocumentPicker() -> some UIViewControllerRepresentable{
        return DocumentPicker(uploadFunc: uploadTracks)
    }
    
    func uploadTracks(urls: [URL]){
        uploadingFile = true
        DispatchQueue.global(qos: .userInitiated).async{
            let uploadService = MusicService.Upload()
            let publisher = uploadService.tracks(urls: urls)
            DispatchQueue.main.async {
                publisher?.subscribe(Subscribers.Sink(
                    receiveCompletion: { result in
                    switch result{
                    case .finished:
                        self.uploadingFile = false
                        self.getUserProfile()
                    case .failure(_):
                        self.uploadingFile = false
                        print("completion failure")
                    }
                },
                receiveValue: {
                    self.uploadProgress = $0
                }))
            }
        }
    }
}
