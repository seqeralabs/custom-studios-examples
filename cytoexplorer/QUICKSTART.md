# Quick Start Guide

## 1. Build the Image

```bash
./build.sh
```

This takes **15-20 minutes** to compile dependencies and install R packages.

## 2. Test Locally (Optional)

```bash
docker run -p 8787:8787 \
  -e PASSWORD=test \
  cytoexplorer-studios:latest
```

Open http://localhost:8787 in your browser:
- **Username:** `rstudio`
- **Password:** `test`

## 3. Push to Registry

```bash
./build.sh --registry ghcr.io/YOUR_USERNAME --push
```

## 4. Deploy to Seqera Platform

1. Go to **Studios** → **Add Studio**
2. Select **Prebuilt container image**
3. Enter: `ghcr.io/YOUR_USERNAME/cytoexplorer-studios:latest`
4. Set resources: 4 CPU, 8GB RAM minimum
5. Click **Add and start**

## 5. Use CytoExploreR

Once RStudio loads in your browser:

```r
library(CytoExploreR)

# Load example data
data(Activation, package = "CytoExploreRData")

# Setup experiment
gs <- cyto_setup(Activation,
                 gatingTemplate = "Activation-gatingTemplate.csv")

# Interactive gating
cyto_gate_draw(gs, parent = "root", alias = "Cells")

# Visualize
cyto_plot(gs, parent = "Cells")
```

## Troubleshooting

### Build fails
- Check Docker has enough resources (8GB RAM recommended)
- Ensure stable internet connection for package downloads

### Can't connect to RStudio
- Check container logs: `docker logs <container-id>`
- Verify port 8787 is not in use: `lsof -i :8787`

### RStudio login fails
- Default credentials: `rstudio` / `rstudio`
- Or set custom: `-e PASSWORD=yourpassword`

## Resources

- [CytoExploreR Documentation](https://dillonhammill.github.io/CytoExploreR/)
- [Seqera Platform Docs](https://docs.seqera.io/)
