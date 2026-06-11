# Plugin Repository Template

A production-ready template for Unreal Engine 5 plugin repositories with automated CI/CD, versioning, and release management.

## 🚀 Quick Start

1. **Use this template** to create a new plugin repository
2. **Set up self-hosted runners** with labels: `self-hosted`, `linux`, `windows`
3. **Configure secrets** (see below)
4. **Start development** on the `development` branch

## 📋 Branch Strategy

This template uses a robust branch management strategy:

### Development Branch (`development`)
- **Purpose**: Latest/experimental builds and features
- **Versioning**: Automatic patch increments based on commits
- **Releases**: Development builds (no GitHub releases)
- **CI**: Full testing and validation
- **Target**: Feature development and testing

### Main Branch (`main`) 
- **Purpose**: Production/stable releases only
- **Versioning**: Semantic versioning (major.minor.patch)
- **Releases**: GitHub releases with release notes
- **CI**: Strict validation before merge
- **Target**: Production deployments

### Workflow

```
development (experimental)
    ↓ (auto-versioning: patches)
    ↓ (CI validation)
    ↓ (PR to main)
main (stable)
    ↓ (approved release)
    ↓ (GitHub Release)
    ↓ (version tag)
production deployments
```

## 🔐 Required Secrets

### Self-Hosted Runners
- **Runner Setup**: Configure organization-level runners with labels `self-hosted`, `Windows`
- **Shared Runner**: This template is designed for shared organization runners (like `TIM-PC`)
- **Runner Requirements**: Windows environment with PowerShell 5.1+

### Optional Storage
- `GOOGLE_SERVICE_ACCOUNT_KEY`: For Google Drive uploads
- `GOOGLE_DRIVE_FOLDER_ID`: Target folder ID
- `MINIO_ACCESS_KEY`: MinIO/S3 access key
- `MINIO_SECRET_KEY`: MinIO/S3 secret key  
- `MINIO_BUCKET_NAME`: Bucket name
- `MINIO_ENDPOINT`: MinIO server endpoint

### Documentation (Optional)
- `WIKIJS_INSTANCE_URL`: Wiki.js instance URL
- `WIKIJS_API_KEY`: Wiki.js API key
- `WIKIJS_DOCUMENTATION_PATH`: Base documentation path

## 🛠️ Workflows

### Automatic Versioning
- **Development**: Auto-increment patch version on commits
- **Main**: Semantic versioning based on commit types
- **Tags**: Automatic version tagging

### CI/CD Pipelines
- **Compile**: Windows and Linux builds
- **Tests**: Automated testing suite
- **Static Analysis**: Code quality checks
- **Release**: Plugin packaging and distribution

### Release Workflows
- **UE5 Builds**: Multi-version builds (5.3.0, 5.4.0, 5.5.0, 5.6.0)
- **GitHub Releases**: Automated release creation
- **Distribution**: GitHub, Google Drive, MinIO

## 📦 Plugin Structure

```
your-plugin/
├── Source/
│   ├── YourPlugin/
│   │   ├── YourPlugin.Build.cs
│   │   ├── Public/
│   │   └── Private/
│   └── YourPluginTests/
├── Resources/
├── Config/
├── .github/
│   ├── workflows/
│   ├── actions/
│   └── scripts/
├── YourPlugin.uplugin
├── README.md
├── CHANGELOG.md
└── LICENSE
```

## 🔄 Version Management

### Development Workflow
1. Create feature branch from `development`
2. Make commits (auto-versioning applies patch increments)
3. Push to `development` (CI runs automatically)
4. Create PR to `main` when ready

### Release Workflow
1. Merge approved feature to `main`
2. Trigger release workflow manually
3. Select release type (major/minor/patch)
4. Workflow creates GitHub release and tags
5. Plugin packages are built and distributed

## 🎯 Usage Examples

### Development Cycle
```bash
# Create feature branch
git checkout -b feature/new-interaction development

# Make changes and commit
git add .
git commit -m "feat: add new interaction system"

# Push to development
git push origin feature/new-interaction

# Create PR to main
```

### Release Cycle
```bash
# Merge to main (via PR)
# Trigger release workflow manually
# Select release type: major/minor/patch
# GitHub release created automatically
```

## 🧪 Testing

All commits trigger automated testing:
- **Compilation**: Windows and Linux builds
- **Unit Tests**: Plugin test suite
- **Static Analysis**: Code quality checks
- **Validation**: Plugin file structure

## 📝 Conventional Commits

Use conventional commit messages for auto-versioning:

- `feat:` → Minor version increment (main)
- `fix:` → Patch version increment
- `perf:` → Patch version increment
- `refactor:` → No version change
- `docs:` → No version change
- `test:` → No version change
- `chore:` → No version change

## 🤝 Contributing

1. Fork the repository
2. Create feature branch from `development`
3. Make your changes
4. Commit with conventional messages
5. Push to your fork
6. Create pull request to `development`

## 📄 License

This template is available under the MIT License.

## 🆘 Support

For issues and questions:
- GitHub Issues: Create a new issue
- Documentation: Check this README and workflow comments
- Workflow Status: Check Actions tab

---

**Template Version**: 1.0.0  
**Last Updated**: 2024  
**Maintained by**: MountainLabsDE