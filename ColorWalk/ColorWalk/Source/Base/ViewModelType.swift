//
//  ViewModelType.swift
//  ColorWalk
//

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    func transform(input: Input) -> Output
}
