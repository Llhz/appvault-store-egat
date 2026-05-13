package com.appvault.service;

import com.appvault.dto.AppSubmissionDto;
import com.appvault.exception.ResourceNotFoundException;
import com.appvault.model.AppSubmission;
import com.appvault.model.SubmissionStatus;
import com.appvault.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class AppSubmissionServiceTest {

    @Autowired
    private AppSubmissionService appSubmissionService;

    @Autowired
    private UserService userService;

    private User developer;
    private User admin;

    @BeforeEach
    void setUp() {
        developer = userService.findByEmail("developer@appvault.com")
                .orElseThrow(() -> new RuntimeException("developer@appvault.com not found in test data"));
        admin = userService.findByEmail("admin@appvault.com")
                .orElseThrow(() -> new RuntimeException("admin@appvault.com not found in test data"));
    }

    private AppSubmissionDto buildDto(String name, String description) {
        AppSubmissionDto dto = new AppSubmissionDto();
        dto.setName(name);
        dto.setDescription(description);
        dto.setDeveloper("TestCorp");
        dto.setPrice(BigDecimal.ZERO);
        return dto;
    }

    @Test
    void createSubmissionSavesAsDraft() {
        AppSubmissionDto dto = buildDto("TestApp", "A test application description.");
        AppSubmission submission = appSubmissionService.createSubmission(dto, developer.getId());

        assertNotNull(submission.getId());
        assertEquals("TestApp", submission.getName());
        assertEquals(SubmissionStatus.DRAFT, submission.getStatus());
        assertEquals(developer.getId(), submission.getSubmitter().getId());
    }

    @Test
    void submitForReviewChangesDraftToPending() {
        AppSubmissionDto dto = buildDto("ReviewApp", "An app to submit for review.");
        AppSubmission submission = appSubmissionService.createSubmission(dto, developer.getId());

        AppSubmission pending = appSubmissionService.submitForReview(submission.getId(), developer.getId());

        assertEquals(SubmissionStatus.PENDING_REVIEW, pending.getStatus());
    }

    @Test
    void approveSubmissionCreatesAppListing() {
        AppSubmissionDto dto = buildDto("ApproveApp", "An app to approve.");
        AppSubmission submission = appSubmissionService.createSubmission(dto, developer.getId());
        appSubmissionService.submitForReview(submission.getId(), developer.getId());

        AppSubmission approved = appSubmissionService.approveSubmission(submission.getId(), "Looks good!");

        assertEquals(SubmissionStatus.APPROVED, approved.getStatus());
        assertEquals("Looks good!", approved.getReviewNotes());
        assertNotNull(approved.getApprovedListingId());
    }

    @Test
    void rejectSubmissionSetsRejectedStatus() {
        AppSubmissionDto dto = buildDto("RejectApp", "An app to reject.");
        AppSubmission submission = appSubmissionService.createSubmission(dto, developer.getId());
        appSubmissionService.submitForReview(submission.getId(), developer.getId());

        AppSubmission rejected = appSubmissionService.rejectSubmission(submission.getId(), "Needs more polish.");

        assertEquals(SubmissionStatus.REJECTED, rejected.getStatus());
        assertEquals("Needs more polish.", rejected.getReviewNotes());
    }

    @Test
    void getSubmissionsByUserReturnsDeveloperSubmissions() {
        List<AppSubmission> submissions = appSubmissionService.getSubmissionsByUser(developer.getId());
        assertNotNull(submissions);
        // DataInitializer seeds 3 sample submissions for developer
        assertFalse(submissions.isEmpty());
        submissions.forEach(s -> assertEquals(developer.getId(), s.getSubmitter().getId()));
    }

    @Test
    void getPendingSubmissionsReturnsPendingOnly() {
        // Create a pending submission
        AppSubmissionDto dto = buildDto("PendingApp", "App pending review.");
        AppSubmission submission = appSubmissionService.createSubmission(dto, developer.getId());
        appSubmissionService.submitForReview(submission.getId(), developer.getId());

        List<AppSubmission> pending = appSubmissionService.getPendingSubmissions();
        assertFalse(pending.isEmpty());
        pending.forEach(s -> assertEquals(SubmissionStatus.PENDING_REVIEW, s.getStatus()));
    }

    @Test
    void getSubmissionByIdThrowsForMissing() {
        assertThrows(ResourceNotFoundException.class, () ->
                appSubmissionService.getSubmissionById(99999L));
    }

    @Test
    void submitForReviewByWrongUserThrows() {
        AppSubmissionDto dto = buildDto("OtherApp", "Not owned by admin.");
        AppSubmission submission = appSubmissionService.createSubmission(dto, developer.getId());

        assertThrows(ResourceNotFoundException.class, () ->
                appSubmissionService.submitForReview(submission.getId(), admin.getId()));
    }

    @Test
    void resubmitRejectedSubmission() {
        AppSubmissionDto dto = buildDto("ResubmitApp", "Going to be rejected then resubmitted.");
        AppSubmission submission = appSubmissionService.createSubmission(dto, developer.getId());
        appSubmissionService.submitForReview(submission.getId(), developer.getId());
        appSubmissionService.rejectSubmission(submission.getId(), "Too basic.");

        AppSubmission resubmitted = appSubmissionService.submitForReview(submission.getId(), developer.getId());
        assertEquals(SubmissionStatus.PENDING_REVIEW, resubmitted.getStatus());
        assertNull(resubmitted.getReviewNotes());
    }
}
