//
//  StudyProfileManager.swift
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

import BridgeApp

open class StudyProfileManager: SBAProfileManagerObject {
    
    let treatmentsProfileKey = "treatmentSelection"
    let treatmentsDateProfileKey = "treatmentSelectionDate"
    let diagnosisProfileKey = "psoriasisStatus"
    let symptomsProfileKey = "psoriasisSymptoms"
    
    let profileTasks = [RSDIdentifier.treatmentTask.rawValue]
    
    open var treatmentStepIdentifiers: [String] {
        return [diagnosisProfileKey, symptomsProfileKey, treatmentsProfileKey, treatmentsDateProfileKey]
    }

    override open func availablePredicate() -> NSPredicate {
        return SBBScheduledActivity.includeTasksPredicate(with: self.profileTasks)
    }
    
    open var treatmentsDate: Date? {
        guard let timeIntervalSince1970 = self.value(forProfileKey: treatmentsDateProfileKey) as? Double else { return nil }
        return Date(timeIntervalSince1970: timeIntervalSince1970)
    }
    
    open var treatmentsDateResult: RSDAnswerResultObject? {
        guard let treatmentsDateUnwrapped = self.treatmentsDate else { return nil }
        return RSDAnswerResultObject(identifier: treatmentsDateProfileKey, answerType: .decimal, value: treatmentsDateUnwrapped)
    }
    
    open var treatments: [String]? {
        return self.value(forProfileKey: treatmentsProfileKey) as? [String]
    }
    
    /// The current value of treatments as an answer result
    open var treatmentsResult: RSDAnswerResultObject? {
        guard let treatmentsUnwrapped = self.treatments else { return nil }
        let stringArrayType = RSDAnswerResultType(baseType: .string, sequenceType: .array, formDataType: .collection(.multipleChoice, .string), dateFormat: nil, unit: nil, sequenceSeparator: nil)
        return RSDAnswerResultObject(identifier: treatmentsProfileKey, answerType: stringArrayType, value: treatmentsUnwrapped)
    }
    
    open var diagnosis: String? {
        return self.value(forProfileKey: diagnosisProfileKey) as? String
    }
    
    /// The current value of diagnosis as an answer result
    open var diagnosisResult: RSDAnswerResultObject? {
        guard let diagnosisUnwrapped = self.diagnosis else { return nil }
        return RSDAnswerResultObject(identifier: diagnosisProfileKey, answerType: .string, value: diagnosisUnwrapped)
    }
    
    open var symptoms: String? {
       return self.value(forProfileKey: symptomsProfileKey) as? String
    }
    
    /// The current value of symptoms as an answer result
    open var symptomsResult: RSDAnswerResultObject? {
        guard let symptomsUnwrapped = self.symptoms else { return nil }
        return RSDAnswerResultObject(identifier: symptomsProfileKey, answerType: .string, value: symptomsUnwrapped)
    }
    
    /// Creates and returns the answer result for the current state of the profile key
    open func answerResult(for profileKey: String) -> RSDAnswerResultObject? {
        switch profileKey {
        case treatmentsProfileKey:
            return self.treatmentsResult
        case symptomsProfileKey:
            return self.symptomsResult
        case diagnosisProfileKey:
            return self.diagnosisResult
        default:
            return nil
        }
    }
    
    override open func reportCategory(for reportIdentifier: String) -> SBAReportCategory {
        if reportIdentifier == RSDIdentifier.treatmentTask.rawValue {
            return .timestamp
        }
        return super.reportCategory(for: reportIdentifier)
    }
    
    override open func reportQueries() -> [SBAReportManager.ReportQuery] {
        
        // There is a bug in SBAReportManager where a report query will be stuck
        // when the user is not authenticated, fix that here
        // TODO: make a jira issue
        if !BridgeSDK.authManager.isAuthenticated() { return [] }
        
        // This will include most recent for quick current treatment access
        var queries = super.reportQueries()
        // Also add the report query for the entire list of treatment history
        if let treatmentQuery = queries.first(where: { $0.reportIdentifier == RSDIdentifier.treatmentTask.rawValue }) {
            queries.append(ReportQuery(reportKey: RSDIdentifier(rawValue: treatmentQuery.reportIdentifier), queryType: .all, dateRange: nil))
        }
        return queries
    }
    
    override open func didUpdateReports(with newReports: [SBAReport]) {
        self.reports = Set(self.reports.sorted(by: { $0.date < $1.date }))
        super.didUpdateReports(with: newReports)
    }
    
    override open func decodeItem(from decoder: Decoder, with type: SBAProfileItemType) throws -> SBAProfileItem? {
        
        switch (type) {
        case .report:
            // TODO remove once this is merged https://github.com/Sage-Bionetworks/BridgeApp-Apple-SDK/pull/184
            let item = try HealthProfileItem(from: decoder)
            item.reportManager = self
            return item
    
        default:
            break
        }
        return try super.decodeItem(from: decoder, with: type)
    }
}

extension SBAProfileSectionType {
    /// Creates a `StudyProfileSection`.
    public static let studySection: SBAProfileSectionType = "studySection"
}

class StudyProfileDataSource: SBAProfileDataSourceObject {

    override open func decodeSection(from decoder:Decoder, with type:SBAProfileSectionType) throws -> SBAProfileSection? {
        switch type {
        case .studySection:
            return try StudyProfileSection(from: decoder)
        default:
            return try super.decodeSection(from: decoder, with: type)
        }
    }

}

extension SBAProfileTableItemType {
    /// Creates a `HealthInformationProfileTableItem`.
    public static let healthInformation: SBAProfileTableItemType = "healthInformation"
}

class StudyProfileSection: SBAProfileSectionObject {

    override open func decodeItem(from decoder:Decoder, with type:SBAProfileTableItemType) throws -> SBAProfileTableItem? {
        
        switch type {
        default:
            return try super.decodeItem(from: decoder, with: type)
        }
    }
}

extension SBAProfileOnSelectedAction {
    public static let healthInformationProfileAction: SBAProfileOnSelectedAction = "healthInformationProfileAction"
}