//
//  ViewController.swift
//  PHPicker_Demo
//
//  Created by JINSEOK on 2023/04/05.
//

import UIKit
import PhotosUI
import SnapKit

class ViewController: UIViewController {
    
    // Identifier와 PHPickerResult로 만든 Dictionary
    private var selections = [String : PHPickerResult]()
    // 선택한 사진의 순서에 맞게 배열로 Identifier들을 저장해줄 겁니다. (딕셔너리는 순서가 없기 때문에)
    private var selectedAssetIdentifiers = [String]()
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.spacing = 10
        stack.axis = .vertical
        stack.distribution = .equalCentering
        return stack
    }()
    
    lazy var button: UIButton = {
        let button = UIButton(frame: CGRect(x: (view.frame.width/2)-50, y: 720, width: 100, height: 60))
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 20
        button.setTitle("PHPicker", for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(button)
        view.addSubview(stackView)
        
        stackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(self.view.safeAreaLayoutGuide).offset(20)
        }
        
        button.addTarget(self, action: #selector(buttonHandler), for: .touchUpInside)
    }
    
    @objc func buttonHandler(_ sender: UIButton) {
        presentPicker()
    }
    
    private func presentPicker() {
        // 이미지의 Identifier를 사용하기 위해서는 초기화를 shared로 해줘야 합니다.
        var config = PHPickerConfiguration(photoLibrary: .shared())
        // 라이브러리에서 보여줄 Assets을 필터를 한다. (기본값: 이미지, 비디오, 라이브포토)
        config.filter = PHPickerFilter.any(of: [.images])
        // 다중 선택 갯수 설정 (0 = 무제한)
        config.selectionLimit = 3
        // 선택 동작을 나타냄 (default: 기본 틱 모양, ordered: 선택한 순서대로 숫자로 표현, people: 뭔지 모르겠게요)
        config.selection = .ordered
        // 잘은 모르겠지만, current로 설정하면 트랜스 코딩을 방지한다고 하네요!?
        config.preferredAssetRepresentationMode = .current
        // 이 동작이 있어야 Picker를 실행 시, 선택했던 이미지를 기억해 표시할 수 있다. (델리게이트 코드 참고)
        config.preselectedAssetIdentifiers = selectedAssetIdentifiers
        
        // 만든 Configuration를 사용해 PHPicker 컨트롤러 객체 생성
        let imagePicker = PHPickerViewController(configuration: config)
        imagePicker.delegate = self
        
        self.present(imagePicker, animated: true)
    }
    
    
    private func displayImage() {
        // 처음 스택뷰의 서브뷰들을 모두 제거함
        self.stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let dispatchGroup = DispatchGroup()
        // identifier와 이미지로 dictionary를 만듬 (selectedAssetIdentifiers의 순서에 따라 이미지를 받을 예정입니다.)
        var imagesDict = [String: UIImage]()

        for (identifier, result) in selections {
            
            dispatchGroup.enter()
                        
            let itemProvider = result.itemProvider
            // 만약 itemProvider에서 UIImage로 로드가 가능하다면?
            if itemProvider.canLoadObject(ofClass: UIImage.self) {
                // 로드 핸들러를 통해 UIImage를 처리해 줍시다. (비동기적으로 동작)
                itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                    
                    guard let image = image as? UIImage else { return }
                    
                    imagesDict[identifier] = image
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) { [weak self] in
            
            guard let self = self else { return }
            
            for identifier in self.selectedAssetIdentifiers {
                guard let image = imagesDict[identifier] else { return }
                self.addImage(image)
            }
        }
    }
    
    
    private func addImage(_ image: UIImage) {
        
        let imageView = UIImageView()
        imageView.image = image
        
        imageView.snp.makeConstraints {
            $0.width.height.equalTo(200)
        }
        
        self.stackView.addArrangedSubview(imageView)
    }
}



extension ViewController : PHPickerViewControllerDelegate {
    // picker가 종료되면 동작 합니다.
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        // picker가 선택이 완료되면 화면 내리기
        picker.dismiss(animated: true)
        
        // Picker의 작업이 끝난 후, 새로 만들어질 selections을 담을 변수를 생성
        var newSelections = [String: PHPickerResult]()
        
        for result in results {
            let identifier = result.assetIdentifier!
            // ⭐️ 여기는 WWDC에서 3분 부분을 참고하세요. (Picker의 사진의 저장 방식)
            newSelections[identifier] = selections[identifier] ?? result
        }
        
        // selections에 새로 만들어진 newSelection을 넣어줍시다.
        selections = newSelections
        // Picker에서 선택한 이미지의 Identifier들을 저장 (assetIdentifier은 옵셔널 값이라서 compactMap 받음)
        // 위의 PHPickerConfiguration에서 사용하기 위해서 입니다.
        selectedAssetIdentifiers = results.compactMap { $0.assetIdentifier }
        
        // 만약 비어있다면 스택뷰 초기화, selection이 하나라도 있다면 displayImage 실행
        if selections.isEmpty {
            stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        } else {
            displayImage()
        }
    }
}


// 9F983DBA
// B84E8479
// 106E99A1

