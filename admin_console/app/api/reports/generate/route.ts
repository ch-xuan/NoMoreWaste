import { NextRequest, NextResponse } from 'next/server'

export async function POST(request: NextRequest) {
    try {
        const { dateRange, format, metrics } = await request.json()

        // Generate mock report data
        const reportData = generateReportData(dateRange, metrics)

        // Convert to requested format
        let blob: Blob
        let contentType: string

        switch (format.toUpperCase()) {
            case 'PDF':
                blob = generatePDFReport(reportData, dateRange)
                contentType = 'application/pdf'
                break
            case 'CSV':
                blob = generateCSVReport(reportData)
                contentType = 'text/csv'
                break
            case 'EXCEL':
                blob = generateExcelReport(reportData)
                contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
                break
            default:
                throw new Error('Unsupported format')
        }

        // Create notification for report completion
        try {
            await fetch(`${request.url.split('/api')[0]}/api/notifications/create`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    type: 'report_available',
                    title: 'New Report Available',
                    message: `${format.toUpperCase()} report for ${dateRange} is ready for download`,
                    linkTo: '/dashboard/reports',
                    metadata: { format, dateRange, generatedAt: new Date().toISOString() }
                }),
            })
        } catch (notifError) {
            console.error('Failed to create notification:', notifError)
            // Don't fail the whole request if notification fails
        }

        return new NextResponse(blob, {
            headers: {
                'Content-Type': contentType,
                'Content-Disposition': `attachment; filename=custom-report-${Date.now()}.${format.toLowerCase()}`,
            },
        })
    } catch (error) {
        console.error('Report generation error:', error)
        return NextResponse.json(
            { error: 'Failed to generate report' },
            { status: 500 }
        )
    }
}

function generateReportData(dateRange: string, metrics: any) {
    return {
        dateRange,
        generatedAt: new Date().toISOString(),
        metrics,
        data: {
            totalDonations: 100,
            successRate: 94.2,
            mealsServed: 123,
            foodByCategory: {
                'Cooked Meals': 45,
                'Fresh Produce': 38,
                'Breads & Pastries': 27,
                'Packaged Goods': 14,
            },
            topDonors: [
                { name: 'Grand Hotel', count: 87 },
                { name: 'Fresh Bakery', count: 65 },
                { name: 'Mega Mart', count: 54 },
            ],
            ngoFulfillment: {
                'Hope Foundation': 96.5,
                'Community Kitchen': 93.2,
                'Food Bank Plus': 98.1,
            },
        },
    }
}

function generatePDFReport(data: any, dateRange: string): Blob {
    // Generate simple PDF-like content
    // In production, use a library like pdfkit or jspdf
    const pdfContent = `%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj
2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj
3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
/Resources <<
/Font <<
/F1 <<
/Type /Font
/Subtype /Type1
/BaseFont /Helvetica
>>
>>
>>
>>
endobj
4 0 obj
<<
/Length 500
>>
stream
BT
/F1 24 Tf
50 750 Td
(NoMoreWaste Admin Dashboard) Tj
0 -30 Td
/F1 18 Tf
(Custom Report) Tj
0 -40 Td
/F1 12 Tf
(Date Range: ${dateRange}) Tj
0 -20 Td
(Generated: ${new Date().toLocaleString()}) Tj
0 -40 Td
(Total Donations: ${data.data.totalDonations}) Tj
0 -20 Td
(Success Rate: ${data.data.successRate}%) Tj
0 -20 Td
(Meals Served: ${data.data.mealsServed}) Tj
0 -40 Td
/F1 14 Tf
(Food by Category:) Tj
0 -20 Td
/F1 12 Tf
${Object.entries(data.data.foodByCategory || {})
            .map(([category, count]) => `(${category}: ${count}) Tj 0 -20 Td`)
            .join('\n')}
ET
endstream
endobj
xref
0 5
0000000000 65535 f
0000000009 00000 n
0000000058 00000 n
0000000115 00000 n
0000000300 00000 n
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
850
%%EOF`

    return new Blob([pdfContent], { type: 'application/pdf' })
}

function generateCSVReport(data: any): Blob {
    const csv = `
"Report Type","Custom Report"
"Date Range","${data.dateRange}"
"Generated At","${new Date().toLocaleString()}"

"Metric","Value"
"Total Donations","${data.data.totalDonations}"
"Success Rate","${data.data.successRate}%"
"Meals Served","${data.data.mealsServed}"

"Food Category","Count"
${Object.entries(data.data.foodByCategory)
            .map(([category, count]) => `"${category}","${count}"`)
            .join('\n')}

"Donor Name","Donation Count"
${data.data.topDonors.map((donor: any) => `"${donor.name}","${donor.count}"`).join('\n')}

"NGO","Fulfillment Rate (%)"
${Object.entries(data.data.ngoFulfillment)
            .map(([ngo, rate]) => `"${ngo}","${rate}"`)
            .join('\n')}
    `.trim()

    return new Blob([csv], { type: 'text/csv' })
}

function generateExcelReport(data: any): Blob {
    // For Excel, we'll generate CSV format
    // In production, use exceljs or xlsx library
    return generateCSVReport(data)
}
