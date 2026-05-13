package com.appvault.controller;

import com.appvault.dto.AppSubmissionDto;
import com.appvault.exception.ResourceNotFoundException;
import com.appvault.model.AppSubmission;
import com.appvault.model.SubmissionStatus;
import com.appvault.model.User;
import com.appvault.repository.CategoryRepository;
import com.appvault.service.AppSubmissionService;
import com.appvault.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/developer")
public class DeveloperController {

    @Autowired private AppSubmissionService appSubmissionService;
    @Autowired private UserService userService;
    @Autowired private CategoryRepository categoryRepository;

    @GetMapping("/dashboard")
    public String dashboard(Authentication auth, Model model) {
        User user = getUser(auth);
        List<AppSubmission> submissions = appSubmissionService.getSubmissionsByUser(user.getId());

        model.addAttribute("submissions", submissions);
        model.addAttribute("totalCount", submissions.size());
        model.addAttribute("draftCount", countByStatus(submissions, SubmissionStatus.DRAFT));
        model.addAttribute("pendingCount", countByStatus(submissions, SubmissionStatus.PENDING_REVIEW));
        model.addAttribute("approvedCount", countByStatus(submissions, SubmissionStatus.APPROVED));
        model.addAttribute("rejectedCount", countByStatus(submissions, SubmissionStatus.REJECTED));
        return "developer/dashboard";
    }

    @GetMapping("/submit")
    public String submitForm(Model model) {
        model.addAttribute("submissionDto", new AppSubmissionDto());
        model.addAttribute("categories", categoryRepository.findAll());
        return "developer/submit-form";
    }

    @PostMapping("/submit")
    public String saveSubmission(@Valid @ModelAttribute("submissionDto") AppSubmissionDto dto,
                                  BindingResult result,
                                  Authentication auth, Model model) {
        if (result.hasErrors()) {
            model.addAttribute("categories", categoryRepository.findAll());
            return "developer/submit-form";
        }
        User user = getUser(auth);
        AppSubmission submission = appSubmissionService.createSubmission(dto, user.getId());
        return "redirect:/developer/submission/" + submission.getId();
    }

    @PostMapping("/submit/{id}/review")
    public String submitForReview(@PathVariable Long id, Authentication auth) {
        User user = getUser(auth);
        appSubmissionService.submitForReview(id, user.getId());
        return "redirect:/developer/submission/" + id + "?submitted";
    }

    @GetMapping("/submission/{id}")
    public String submissionDetail(@PathVariable Long id, Authentication auth, Model model) {
        User user = getUser(auth);
        AppSubmission submission = appSubmissionService.getSubmissionById(id);
        if (!submission.getSubmitter().getId().equals(user.getId())) {
            throw new ResourceNotFoundException("Submission not found with id: " + id);
        }
        model.addAttribute("submission", submission);
        return "developer/submission-detail";
    }

    private User getUser(Authentication auth) {
        return userService.findByEmail(auth.getName())
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private long countByStatus(List<AppSubmission> submissions, SubmissionStatus status) {
        return submissions.stream().filter(s -> s.getStatus() == status).count();
    }
}
