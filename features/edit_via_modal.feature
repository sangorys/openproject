Feature: Edit issue via modal box

  Background:
    Given there is 1 project with:
        | name  | ecookbook |
    And I am working in project "ecookbook"
    And the project uses the following modules:
        | backlogs |
    And there is a role "scrum master"
    And the role "scrum master" may have the following rights:
        | view_master_backlog     |
        | view_taskboards         |
        | update_sprints          |
        | update_stories          |
        | create_impediments      |
        | update_impediments      |
        | update_tasks            |
        | view_wiki_pages         |
        | edit_wiki_pages         |
        | view_issues             |
        | edit_issues             |
        | manage_subtasks         |
    And the backlogs module is initialized
    And the following trackers are configured to track stories:
        | Story |
    And the tracker "Task" is configured to track tasks
    And the project uses the following trackers:
        | Story |
        | Task  |
    And the tracker "Task" has the default workflow for the role "scrum master"
    And there is 1 user with:
        | login | markus |
        | firstname | Markus |
        | Lastname | Master |
    And the user "markus" is a "scrum master"
    And the project has the following sprints:
        | name       | start_date | effective_date  |
        | Sprint 001 | 2010-01-01        | 2010-01-31      |
    And the project has the following stories in the following sprints:
        | subject | sprint     |
        | Story A | Sprint 001 |
    And I am already logged in as "markus"

  @javascript
  Scenario: Edit issue via modal box
    When I go to the master backlog
    And I follow "1"
    And I wait for AJAX
    And I follow "Update" within ".contextual"
    And fill in "Story A changed" for "issue_subject"
    And I follow "Save"
    And I wait for AJAX

    Then I should see "Subject changed from Story A to Story A changed" within ".modal"

    When I go to the master backlog

    Then I should see "Story A changed"
