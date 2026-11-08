function downloadExcel() {
    const data = [
        ['col1', 'col2', 'col3'],
        [1, 2, 'a'],
        [3, 4, 'b']
    ]
    // Create a new Excel workbook
    const workbook = XLSX.utils.book_new();
    // Convert data to a worksheet
    const worksheet = XLSX.utils.aoa_to_sheet(data);
    // Add worksheet to the workbook
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
    // Generate Excel file as a Blob
    const excelBlob = XLSX.write(workbook, { bookType: 'xlsx', type: 'array' });
    // Create and click download link.
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([excelBlob], { type: 'application/octet-stream' }));
    a.download = 'file.xlsx';
    a.click();
    // remove the element
    a.remove();
}

function downloadCSV() {
    var data = [
        ["Col1", "Col2", "Col3"],
        ["A1", "B1", "C1"],
        ["A2", "B2", "C2"],
        ["A3", "B3", "C3"]
    ]
    // create a new excel workbook
    const workbook = XLSX.utils.book_new()
    // create worksheet that contains the data
    const worksheet = XLSX.utils.aoa_to_sheet(data);
    // Add worksheet to the workbook
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Sheet1');
    // Generate Excel file as a Blob
    const excelBlob = XLSX.write(workbook, { bookType: 'csv', type: 'array' });
    // Create and click download link.
    const a = document.createElement('a');
    a.href = URL.createObjectURL(new Blob([excelBlob], { type: 'application/octet-stream' }));
    a.download = 'file.csv';
    a.click();
    // remove the element
    a.remove();
}

