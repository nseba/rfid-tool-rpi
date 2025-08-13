# Pull Request

## Description
Brief description of what this PR does and why it's needed.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Performance improvement
- [ ] Code refactoring
- [ ] Dependency update
- [ ] CI/CD improvement

## Related Issues
- Closes #(issue number)
- Relates to #(issue number)
- Depends on #(PR number)

## Changes Made
### Added
- 
- 

### Changed
- 
- 

### Removed
- 
- 

### Fixed
- 
- 

## Hardware Impact
- [ ] No hardware changes required
- [ ] New GPIO pin assignments
- [ ] New hardware components required
- [ ] Wiring changes required
- [ ] Power requirements changed

## Interface Impact
- [ ] Web interface changes
- [ ] Hardware interface changes
- [ ] API changes (breaking/non-breaking)
- [ ] Configuration file changes
- [ ] New dependencies added

## Testing
### Automated Tests
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Code coverage maintained/improved

### Manual Testing
- [ ] Tested on Raspberry Pi 2B
- [ ] Tested on Raspberry Pi 3/4 (if available)
- [ ] Web interface tested in multiple browsers
- [ ] Hardware interface tested with physical components
- [ ] RFID operations tested with multiple card types:
  - [ ] MIFARE Classic 1K
  - [ ] MIFARE Classic 4K
  - [ ] MIFARE Ultralight
  - [ ] Other: ____________

### Test Environment
- **Hardware:** [Pi model, RC522 module, additional components]
- **OS:** [Raspberry Pi OS version]
- **Browser:** [if web interface changes]
- **Cards Tested:** [card types and quantities]

## Configuration Changes
- [ ] No configuration changes
- [ ] Backward compatible configuration changes
- [ ] Breaking configuration changes (requires migration)
- [ ] New configuration options added

If configuration changes are required, describe migration steps:
```bash
# Example migration commands
```

## Performance Impact
- [ ] No performance impact
- [ ] Performance improved
- [ ] Performance may be affected (explain below)
- [ ] Memory usage impact (explain below)

**Performance Details:**
[If applicable, describe any performance implications]

## Documentation Updates
- [ ] README.md updated
- [ ] WIRING.md updated
- [ ] QUICKSTART.md updated
- [ ] API documentation updated
- [ ] Code comments added/updated
- [ ] No documentation changes needed

## Security Considerations
- [ ] No security impact
- [ ] Security improvement
- [ ] Potential security impact (explain below)
- [ ] New security features added

**Security Details:**
[If applicable, describe any security implications]

## Deployment Notes
- [ ] No special deployment steps required
- [ ] Service restart required
- [ ] Configuration update required
- [ ] System reboot required
- [ ] Hardware rewiring required

**Deployment Steps:**
1. 
2. 
3. 

## Breaking Changes
- [ ] No breaking changes
- [ ] API breaking changes
- [ ] Configuration breaking changes
- [ ] Hardware setup breaking changes

**Migration Guide:**
[If breaking changes, provide migration steps]

## Screenshots/Demo
[If applicable, add screenshots or demo videos showing the changes]

## Checklist
### Code Quality
- [ ] Code follows project style guidelines
- [ ] Self-review of code completed
- [ ] Code is properly commented
- [ ] No debug logging left in production code
- [ ] Error handling is comprehensive

### Testing
- [ ] All automated tests pass
- [ ] Manual testing completed
- [ ] Edge cases considered and tested
- [ ] Error conditions tested

### Documentation
- [ ] Relevant documentation updated
- [ ] Code comments added for complex logic
- [ ] API changes documented
- [ ] Breaking changes documented with migration guide

### Dependencies
- [ ] No new dependencies added OR new dependencies justified
- [ ] go.mod and go.sum updated if needed
- [ ] No vulnerable dependencies introduced
- [ ] License compatibility verified for new dependencies

### Security
- [ ] No sensitive data exposed
- [ ] Input validation implemented
- [ ] Authentication/authorization considered
- [ ] Security best practices followed

## Additional Notes
[Any additional information that reviewers should know]

## Post-Merge Tasks
- [ ] Update project version
- [ ] Create/update release notes
- [ ] Update installation documentation
- [ ] Notify users of breaking changes
- [ ] Update Docker image (if applicable)

---

**Reviewer Guidelines:**
- Verify all checklist items are completed
- Test on actual hardware if possible
- Check for breaking changes and migration path
- Validate documentation updates
- Ensure consistent code style