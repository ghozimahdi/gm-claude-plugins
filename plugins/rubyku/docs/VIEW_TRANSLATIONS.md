# View Translations

## Directory Structure

```
config/locales/
├── ja.yml                           # General translations
├── en.yml                           # English translations
├── devise.ja.yml                    # Devise translations
├── models/                          # Model attribute translations
│   ├── user.ja.yml
│   └── task.ja.yml
└── views/                           # View translations
    ├── shared/                      # Shared UI elements
    │   ├── buttons.id.yml
    │   └── flash.id.yml
    └── t/                           # Talent namespace (/t)
        ├── dashboards.id.yml
        ├── tasks.id.yml
        └── tasks/           # Nested routes
            └── contracts.id.yml
```

## Rules

### 1. Organize by Namespace and Controller
One YAML file per controller within the namespace directory:
```
config/locales/views/{namespace}/{controller}.{locale}.yml
```

For nested routes:
```
config/locales/views/{namespace}/{parent}/{nested_controller}.{locale}.yml
```

### 2. Key Structure Must Match View Path
For Rails lazy lookup to work:

```yaml
# config/locales/views/t/tasks.id.yml
id:
  t:
    tasks:
      index:
        title: "Daftar Tugas"
      show:
        title: "Detail Tugas"
```

### 3. Use Lazy Lookup in Views
```erb
<%# Good — lazy lookup %>
<h1><%= t('.title') %></h1>

<%# Bad — full key path %>
<h1><%= t('t.tasks.index.title') %></h1>
```

### 4. Shared UI in `shared/` Directory
```yaml
# config/locales/views/shared/buttons.id.yml
id:
  shared:
    buttons:
      save: "Simpan"
      cancel: "Batal"
      delete: "Hapus"
```

### 5. Interpolation for Dynamic Content
```yaml
id:
  t:
    dashboards:
      welcome: "Selamat datang, %{name}!"
```
```erb
<%= t('.welcome', name: current_user.name) %>
```

### 6. Pluralization
```yaml
id:
  t:
    tasks:
      count:
        zero: "Tidak ada tugas"
        one: "1 tugas"
        other: "%{count} tugas"
```

### 7. Separate Model Attributes from View Text
- **Model attributes** (form labels, table headers): `config/locales/models/`
- **View-specific text** (page titles, messages): `config/locales/views/`
