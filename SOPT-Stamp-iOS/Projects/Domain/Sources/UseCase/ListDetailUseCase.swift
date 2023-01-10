//
//  ListDetailUseCase.swift
//  Presentation
//
//  Created by 양수빈 on 2022/11/28.
//  Copyright © 2022 SOPT-Stamp-iOS. All rights reserved.
//

import Core

import Combine

public protocol ListDetailUseCase {
    func fetchListDetail(missionId: Int)
    func fetchOtherListDetail(userId: Int, missionId: Int)
    func postStamp(missionId: Int, stampData: ListDetailRequestModel)
    func putStamp(missionId: Int, stampData: ListDetailRequestModel)
    func deleteStamp(stampId: Int)
    var listDetailModel: PassthroughSubject<ListDetailModel, Error> { get set }
    var editSuccess: PassthroughSubject<Bool, Error> { get set }
    var deleteSuccess: PassthroughSubject<Bool, Error> { get set }
}

public class DefaultListDetailUseCase {
  
    private let repository: ListDetailRepositoryInterface
    private var cancelBag = CancelBag()
    
    public var listDetailModel = PassthroughSubject<ListDetailModel, Error>()
    public var editSuccess = PassthroughSubject<Bool, Error>()
    public var deleteSuccess = PassthroughSubject<Bool, Error>()
  
    public init(repository: ListDetailRepositoryInterface) {
        self.repository = repository
    }
}

extension DefaultListDetailUseCase: ListDetailUseCase {
    public func fetchListDetail(missionId: Int) {
        repository.fetchListDetail(missionId: missionId, userId: nil)
            .sink { model in
                self.listDetailModel.send(model)
            }.store(in: self.cancelBag)
    }
    
    public func fetchOtherListDetail(userId: Int, missionId: Int) {
        repository.fetchListDetail(missionId: missionId, userId: userId)
            .sink { model in
                self.listDetailModel.send(model)
            }.store(in: self.cancelBag)
    }
    
    public func postStamp(missionId: Int, stampData: ListDetailRequestModel) {
        let data = [stampData.imgURL as Any, stampData.content] as [Any]
        repository.postStamp(missionId: missionId, stampData: data)
            .replaceError(with: ListDetailModel(image: "", content: "", date: "", stampId: 0))
            .sink { event in
                print("completion: \(event)")
            } receiveValue: { model in
                self.listDetailModel.send(model)
            }.store(in: self.cancelBag)
    }
    
    public func putStamp(missionId: Int, stampData: ListDetailRequestModel) {
        let data = [stampData.imgURL as Any, stampData.content] as [Any]
        repository.putStamp(missionId: missionId, stampData: data)
            .replaceError(with: -1)
            .sink { result in
                self.editSuccess.send(result == -1 ? false: true)
            }.store(in: self.cancelBag)
    }
    
    public func deleteStamp(stampId: Int) {
        repository.deleteStamp(stampId: stampId)
            .replaceError(with: false)
            .sink { success in
                self.deleteSuccess.send(success)
            }.store(in: self.cancelBag)
    }
}
