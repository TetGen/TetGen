# Contributor License Agreement (CLA)

A "Contributor" is any person or entity that intentionally submits copyrighted material to the project,
including but not limited to code, documentation, or other material, via a pull request, issue, or other means.

By submitting a contribution Contributor agrees to the following terms:

## Dual AGPLv3/MIT License Grant
Contributor agrees that their contribution is provided under the GNU Affero General Public License v3 (AGPLv3) reproduced
in the file [LICENSE](LICENSE) or any later version and, in addition, grants the contribution under the MIT License terms below:

```text
Permission is hereby granted, free of charge, to any person obtaining a copy  
of this software and associated documentation files (the "Software"), to deal  
in the Software without restriction, including without limitation the rights  
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell  
copies of the Software, and to permit persons to whom the Software is  
furnished to do so, subject to the following conditions:  

The above copyright notice and this permission notice shall be included in all  
copies or substantial portions of the Software.  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR  
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE  
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER  
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  
SOFTWARE.  
```

## Annotating contributions to source code

### Trivial changes
Trivial changes (e.g., 1-2 line fixes or typo fixes) inherit the AGPLv3 license of the project and without further annotation are also licensed under MIT as specified above.

### Functions and nontrivial snippets of code 
Functions and nontrivial snippets of code by default inherit the AGPLv3 license of the project and are also licensed under MIT as specified above. They shall be marked in a PR with an SPDX header as in this example:
  ```
  # SPDX-License-Identifier: AGPL-3.0-or-later OR MIT
  # Copyright (c) [Year] [Contributor Name]
  void frobnicate(int ntet)
  {
  ...
  }
  ```

## Representations and Warranties
Contributor represents that:
- They are legally entitled to grant the above licenses;
- Their contributions are original works and do not violate third-party rights;
- They are not required to grant licenses under third-party terms (e.g., employer agreements).

## No Obligation
The Project is under no obligation to accept or use any contribution.

