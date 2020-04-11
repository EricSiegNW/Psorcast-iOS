//
//  ProfileTabViewController.swift
//  Psorcast
//
//  Copyright © 2019 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import UIKit
import BridgeApp
import BridgeSDK
import MotorControl

class ProfileTabViewController: UITableViewController, RSDTaskViewControllerDelegate {
    
    /// The profile manager
    let profileManager = (AppDelegate.shared as? AppDelegate)?.profileManager
    let profileDataSource = (AppDelegate.shared as? AppDelegate)?.profileDataSource
    
    open var design = AppDelegate.designSystem
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTableView()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tableView.reloadData()
        
        // Reload the schedules and add an observer to observe changes.
        if let manager = profileManager {
            NotificationCenter.default.addObserver(forName: .SBAUpdatedReports, object: manager, queue: OperationQueue.main) { (notification) in
                self.tableView.reloadData()
            }
        }
    }

    func setupTableView() {
        self.tableView.estimatedSectionHeaderHeight = 40
        
        self.tableView.register(ProfileTableHeaderView.self, forHeaderFooterViewReuseIdentifier: ProfileTableHeaderView.className)
        
        self.tableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileTableViewCell.self))
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 100))
        header.backgroundColor = design.colorRules.backgroundPrimary.color
        let title = UILabel(frame: CGRect(x: 24, y: 33, width: self.view.bounds.width - 48, height: 33))
        title.font = self.design.fontRules.font(for: .largeHeader)
        title.textColor = self.design.colorRules.textColor(on: design.colorRules.backgroundPrimary, for: .largeHeader)
        title.text = Localization.localizedString("PROFILE_TITLE")
        header.addSubview(title)
        self.tableView.tableHeaderView = header
    }
    
    // MARK: - Table view data source
       
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.profileDataSource?.numberOfSections() ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.profileDataSource?.numberOfRows(for: section) ?? 0
    }
   
    func itemForRow(at indexPath: IndexPath) -> SBAProfileTableItem? {
        return self.profileDataSource?.profileTableItem(at: indexPath)
    }
   
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableItem = itemForRow(at: indexPath)
        let titleText = tableItem?.title
        let detailText = tableItem?.detail
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileTableViewCell.self), for: indexPath) as! ProfileTableViewCell
       
        // Configure the cell...
        cell.titleLabel?.text = titleText
        cell.detailLabel?.text = detailText
        cell.setDesignSystem(self.design, with: RSDColorTile(RSDColor.white, usesLightStyle: true))
       
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard self.profileDataSource?.title(for: section) != nil else { return CGFloat.leastNormalMagnitude }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return self.tableView.estimatedSectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.tableView.estimatedRowHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = self.profileDataSource?.title(for: section) else { return nil }
        
        let sectionHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: ProfileTableHeaderView.className) as! ProfileTableHeaderView
        sectionHeaderView.titleLabel?.text = title
        
        return sectionHeaderView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.bounds.width, height: 8))
        footer.backgroundColor = self.design.colorRules.backgroundPrimary.color
        return footer
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let item = itemForRow(at: indexPath),
                let onSelected = item.onSelected
            else {
            return
        }
        
        if let profileItem = item as? SBAProfileItemProfileTableItem,
            let vc = ProfileTabViewController.createTreatmentProfileVc(profileManager: self.profileManager, for: profileItem.profileItemKey) {
            vc.delegate = self
            self.show(vc, sender: self)
        }
        
        // TMight need these as we add more profile items
//        switch onSelected {
//            case SBAProfileOnSelectedAction.prof
//                self.showHealthInformationItem(for: (item as? HealthInformationProfileTableItem)?.profileItemKey)
//                break
//            default:
//                break
//        }
    }
    
    /// Create the individual treatment profile view controller
    public static func createTreatmentProfileVc(profileManager: StudyProfileManager?, for profileKey: String?) -> RSDTaskViewController? {
        guard let key = profileKey else { return nil }
        
        let resource = RSDResourceTransformerObject(resourceName: "Treatment.json", bundle: Bundle.main)
        do {
            let task = try RSDFactory.shared.decodeTask(with: resource)
            if let step = task.stepNavigator.step(with: key) {
                var navigator = RSDConditionalStepNavigatorObject(with: [step])
                navigator.progressMarkers = []
                let task = RSDTaskObject(identifier: RSDIdentifier.treatmentTask.rawValue, stepNavigator: navigator)
                let vc = RSDTaskViewController(task: task)
                
                // Set the initial state of the question answer
                if let prevAnswer = profileManager?.answerResult(for: key) {
                    vc.taskViewModel.append(previousResult: prevAnswer)
                }
                
                return vc
            }
        } catch {
            NSLog("Failed to create task from Onboarding.json \(error)")
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            let background = RSDColorTile(RSDColor.white, usesLightStyle: true)
            cell.contentView.backgroundColor = self.design.colorRules.tableCellBackground(on: background, isSelected: true).color
        }
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.contentView.backgroundColor = RSDColor.white
        }
    }
    
    // MARK: - Task view controller delegate
    
    func taskController(_ taskController: RSDTaskController, didFinishWith reason: RSDTaskFinishReason, error: Error?) {
        self.profileManager?.taskController(taskController, didFinishWith: reason, error: error)
        self.dismiss(animated: true, completion: nil)
    }
    
    func taskController(_ taskController: RSDTaskController, readyToSave taskViewModel: RSDTaskViewModel) {
        let prepared = ProfileTabViewController.prepareTreatmentResultForUpload(profileManager: self.profileManager, taskViewModel: taskViewModel)
        self.profileManager?.taskController(taskController, readyToSave: prepared)
    }
    
    // If we just upload the answer to the individual question,
    // the report data will be incomplete when we search later
    // Let's build the full expected treatment task answers each time
    public static func prepareTreatmentResultForUpload(profileManager: StudyProfileManager?, taskViewModel: RSDTaskViewModel) -> RSDTaskViewModel {
        if taskViewModel.task?.identifier == RSDIdentifier.treatmentTask.identifierValue {
            for treatmentStepId in profileManager?.treatmentStepIdentifiers ?? [] {
                // Don't overwrite any answers from the task
                if taskViewModel.taskResult.findResult(with: treatmentStepId) == nil,
                    let current = profileManager?.answerResult(for: treatmentStepId) {
                    // Append the current state of the rest of the treatments task
                    taskViewModel.taskResult.appendStepHistory(with: current)
                }
            }
        }
        return taskViewModel
    }
}

class ProfileTableHeaderView: RSDTableSectionHeader {
    static let className = String(describing: ProfileTableHeaderView.self)
}

open class ProfileTableViewCell: RSDSelectionTableViewCell {
    
    internal let kLeadingMargin: CGFloat = 48.0
    
    @IBOutlet public var chevron: UIImageView?
    
    override open var isSelected: Bool {
        didSet {
            titleLabel?.font = self.designSystem?.fontRules.font(for: .mediumHeader)
        }
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Add the line separator
        chevron = UIImageView()
        chevron?.image = UIImage(named: "RightChevron")
        chevron!.contentMode = .scaleAspectFit
        contentView.addSubview(chevron!)
        
        chevron!.translatesAutoresizingMaskIntoConstraints = false
        chevron!.rsd_makeWidth(.equal, 18.0)
        chevron!.rsd_makeHeight(.equal, 18.0)
        chevron!.rsd_alignToSuperview([.trailing], padding: 24.0)
        chevron!.rsd_alignCenterVertical(padding: 0.0)
        
        // The title and detail need larger leading margins per design
        if let oldLeading = titleLabel?.superview?.constraints.first(where: { $0.firstAttribute == .leading && ($0.firstItem as? UILabel) == titleLabel }) {
            titleLabel?.superview?.removeConstraint(oldLeading)
            titleLabel?.rsd_alignToSuperview([.leading], padding: kLeadingMargin)
        }
        if let oldLeading = detailLabel?.superview?.constraints.first(where: { $0.firstAttribute == .leading && ($0.firstItem as? UILabel) == detailLabel }) {
            detailLabel?.superview?.removeConstraint(oldLeading)
            detailLabel?.rsd_alignToSuperview([.leading], padding: kLeadingMargin)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override open func setDesignSystem(_ designSystem: RSDDesignSystem, with background: RSDColorTile) {
        super.setDesignSystem(designSystem, with: background)
        chevron?.image = chevron?.image?.rsd_applyColor(designSystem.colorRules.palette.secondary.normal.color)
        
        titleLabel?.font = designSystem.fontRules.font(for: .mediumHeader)
    }
}