# 📊 iTraceLink Project Diagrams

This directory contains PlantUML source files for all project diagrams. PlantUML is a text-based diagramming tool that generates professional diagrams from simple text descriptions.

## 📁 Available Diagrams

1. **use_case_diagram.puml** - System use cases and user interactions
2. **system_architecture.puml** - High-level system architecture
3. **database_schema.puml** - Firestore database structure
4. **order_lifecycle_sequence.puml** - Complete order processing flow
5. **traceability_verification_sequence.puml** - Product verification process
6. **component_diagram.puml** - Flutter app internal structure
7. **deployment_diagram.puml** - Environment deployment architecture

## 🛠️ How to View/Render Diagrams

### Option 1: Online PlantUML Server
1. Copy the content of any `.puml` file
2. Go to [PlantUML Online Server](http://www.plantuml.com/plantuml/)
3. Paste the content and click "Submit"

### Option 2: VS Code Extension
1. Install the "PlantUML" extension in VS Code
2. Open any `.puml` file
3. Right-click and select "Preview Current Diagram"

### Option 3: PlantUML CLI (if installed)
```bash
# Install PlantUML (requires Java)
plantuml use_case_diagram.puml

# Generate PNG
plantuml -tpng use_case_diagram.puml

# Generate SVG
plantuml -tsvg use_case_diagram.puml
```

### Option 4: IntelliJ/IDEA Plugin
1. Install PlantUML Integration plugin
2. Open `.puml` files and view live preview

## 📋 Diagram Usage Guide

### For Developers
- **Use Case Diagram**: Understand user requirements and system capabilities
- **Component Diagram**: Navigate and maintain code structure
- **Sequence Diagrams**: Implement business logic and test scenarios

### For Stakeholders
- **System Architecture**: High-level system understanding
- **Database Schema**: Data relationships and business entities
- **Deployment Diagram**: Infrastructure and scaling decisions

### For QA/Testing
- **Sequence Diagrams**: Create test cases and validation scenarios
- **Use Case Diagram**: Define acceptance criteria

## 🔄 Maintenance

When the system evolves:
1. Update the corresponding `.puml` files
2. Regenerate diagrams for documentation
3. Update any embedded diagram references in README files

## 📝 File Format

All diagrams use standard PlantUML syntax:
- `@startuml` / `@enduml` - Diagram boundaries
- `actor` - External users/actors
- `component` - System components
- `database` - Data storage elements
- Arrows (`-->`, `-->`) - Relationships and flows

## 🎯 Best Practices

- Keep diagrams simple and focused
- Use consistent naming conventions
- Add notes for complex relationships
- Update diagrams when functionality changes
- Use version control for diagram changes

---

*Generated diagrams for iTraceLink Agricultural Traceability System*
