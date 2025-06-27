// import * as functions from 'firebase-functions';
// import * as admin from 'firebase-admin';
// import * as nodemailer from 'nodemailer';

// admin.initializeApp();
// const db = admin.firestore();

// // Configure email transport
// const mailTransport = nodemailer.createTransport({
//   service: 'gmail',
//   auth: {
//     user: functions.config().email.user="learnitjohn13@gmail.com",
//     pass: functions.config().email.password="plep elze zplg fxfd",
//   },
// });

// const APP_NAME = 'School Management System';
// const SCHOOL_NAME = 'PBTS School';
// const FROM_EMAIL = functions.config().email.user;

// /**
//  * Generates a payment receipt in HTML format
//  */
// function generateReceiptHtml(paymentData: any, studentData: any): string {
//   const date = new Date(paymentData.timestamp.toDate()).toLocaleDateString();
//   const time = new Date(paymentData.timestamp.toDate()).toLocaleTimeString();
//   const amount = paymentData.amount.toFixed(2);
//   const totalFee = paymentData.totalFeeAmount.toFixed(2);
//   const balance = paymentData.balanceRemaining.toFixed(2);
  
//   // Format enrollment type and payment type
//   const enrollmentType = paymentData.enrollmentType || 'Standard Enrollment';
//   const paymentPlanType = paymentData.paymentPlanType || 'Installment';
//   const paymentMethod = paymentData.paymentMethod || 'Cash';
  
//   // Build receipt HTML
//   return `
//     <html>
//       <head>
//         <style>
//           body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
//           .receipt { max-width: 800px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; }
//           .header { text-align: center; border-bottom: 2px solid #3f51b5; padding-bottom: 10px; margin-bottom: 20px; }
//           .school-name { font-size: 24px; font-weight: bold; color: #3f51b5; }
//           .receipt-title { font-size: 18px; margin: 10px 0; }
//           .section { margin: 15px 0; }
//           .section-title { font-weight: bold; margin-bottom: 5px; }
//           .row { display: flex; justify-content: space-between; margin: 5px 0; }
//           .label { font-weight: bold; }
//           .footer { margin-top: 30px; border-top: 1px solid #ddd; padding-top: 10px; font-size: 12px; text-align: center; }
//           .total { font-size: 18px; font-weight: bold; margin: 15px 0; border-top: 1px dashed #ddd; padding-top: 10px; }
//         </style>
//       </head>
//       <body>
//         <div class="receipt">
//           <div class="header">
//             <div class="school-name">${SCHOOL_NAME}</div>
//             <div class="receipt-title">PAYMENT RECEIPT</div>
//             <div>Receipt #: ${paymentData.id}</div>
//           </div>
          
//           <div class="section">
//             <div class="section-title">STUDENT INFORMATION</div>
//             <div class="row">
//               <span class="label">Name:</span>
//               <span>${studentData.lastName}, ${studentData.firstName} ${studentData.middleName || ''}</span>
//             </div>
//             <div class="row">
//               <span class="label">ID:</span>
//               <span>${paymentData.studentId}</span>
//             </div>
//             <div class="row">
//               <span class="label">Grade Level:</span>
//               <span>${paymentData.gradeLevel || studentData.gradeLevel}</span>
//             </div>
//             ${paymentData.course ? `
//             <div class="row">
//               <span class="label">Course:</span>
//               <span>${paymentData.course}</span>
//             </div>` : ''}
//             ${paymentData.semester ? `
//             <div class="row">
//               <span class="label">Semester:</span>
//               <span>${paymentData.semester}</span>
//             </div>` : ''}
//           </div>
          
//           <div class="section">
//             <div class="section-title">PAYMENT DETAILS</div>
//             <div class="row">
//               <span class="label">Date:</span>
//               <span>${date}</span>
//             </div>
//             <div class="row">
//               <span class="label">Time:</span>
//               <span>${time}</span>
//             </div>
//             <div class="row">
//               <span class="label">Academic Year:</span>
//               <span>${paymentData.academicYear}</span>
//             </div>
//             <div class="row">
//               <span class="label">Enrollment Type:</span>
//               <span>${enrollmentType}</span>
//             </div>
//             <div class="row">
//               <span class="label">Payment Plan:</span>
//               <span>${paymentPlanType}</span>
//             </div>
//             <div class="row">
//               <span class="label">Payment Method:</span>
//               <span>${paymentMethod}</span>
//             </div>
//             ${paymentData.scholarshipType ? `
//             <div class="row">
//               <span class="label">Scholarship:</span>
//               <span>${paymentData.scholarshipType} (${paymentData.scholarshipPercentage}%)</span>
//             </div>` : ''}
//             ${paymentData.discountType && paymentData.discountType !== 'None' ? `
//             <div class="row">
//               <span class="label">Discount:</span>
//               <span>${paymentData.discountType} (₱${paymentData.discountAmount?.toFixed(2) || '0.00'})</span>
//             </div>` : ''}
//             ${paymentData.notes ? `
//             <div class="row">
//               <span class="label">Notes:</span>
//               <span>${paymentData.notes}</span>
//             </div>` : ''}
//           </div>
          
//           <div class="section">
//             <div class="section-title">AMOUNT</div>
//             <div class="row">
//               <span class="label">Total Fee:</span>
//               <span>₱${totalFee}</span>
//             </div>
//             <div class="row">
//               <span class="label">Amount Paid:</span>
//               <span>₱${amount}</span>
//             </div>
//             <div class="row">
//               <span class="label">Remaining Balance:</span>
//               <span>₱${balance}</span>
//             </div>
//             <div class="total">
//               <div class="row">
//                 <span class="label">PAYMENT RECEIVED:</span>
//                 <span>₱${amount}</span>
//               </div>
//             </div>
//           </div>
          
//           <div class="section">
//             <div class="section-title">RECEIVED BY</div>
//             <div class="row">
//               <span class="label">Cashier:</span>
//               <span>${paymentData.cashierName}</span>
//             </div>
//           </div>
          
//           <div class="footer">
//             <p>Thank you for your payment! This is an official receipt from ${SCHOOL_NAME}.</p>
//             <p>For questions or concerns about this payment, please contact our accounting office.</p>
//             <p>This receipt was automatically generated by ${APP_NAME}.</p>
//           </div>
//         </div>
//       </body>
//     </html>
//   `;
// }

// /**
//  * Trigger: When a new payment document is created
//  * Action: Generate and send receipt via email
//  */
// export const sendPaymentReceipt = functions.firestore
//   .document('payments/{paymentId}')
//   .onCreate(async (snapshot, context) => {
//     const paymentData = snapshot.data();
//     const paymentId = context.params.paymentId;
    
//     // Add ID to the payment data
//     paymentData.id = paymentId;
    
//     try {
//       // Get student data
//       const studentDoc = await db.collection('students').doc(paymentData.studentId).get();
      
//       if (!studentDoc.exists) {
//         console.error(`Student with ID ${paymentData.studentId} not found`);
//         return null;
//       }
      
//       const studentData = studentDoc.data();
      
//       // Get parent email
//       let parentEmail = '';
      
//       if (paymentData.enrollmentId) {
//         // Try to get parent email from enrollment
//         const enrollmentDoc = await db.collection('enrollments').doc(paymentData.enrollmentId).get();
        
//         if (enrollmentDoc.exists) {
//           const enrollmentData = enrollmentDoc.data();
//           const parentInfo = enrollmentData?.parentInfo || {};
          
//           // Check if parent email exists in parent info
//           if (parentInfo.email) {
//             parentEmail = parentInfo.email;
//           }
//         }
//       }
      
//       // If no parent email found, use system notification email
//       if (!parentEmail) {
//         // parentEmail = functions.config().notification.email;
//         parentEmail = functions.config().notification.email || "learnitjohn13@gmail.com";
//       }
      
//       // Generate receipt HTML
//       const receiptHtml = generateReceiptHtml(paymentData, studentData);
      
//       // Send email
//       const mailOptions = {
//         from: `"${SCHOOL_NAME}" <${FROM_EMAIL}>`,
//         to: parentEmail,
//         subject: `Payment Receipt - ${studentData.firstName} ${studentData.lastName}`,
//         html: receiptHtml,
//       };
      
//       await mailTransport.sendMail(mailOptions);
      
//       // Update payment document with receipt status
//       await snapshot.ref.update({
//         receiptSent: true,
//         receiptTimestamp: admin.firestore.FieldValue.serverTimestamp(),
//       });
      
//       console.log(`Payment receipt sent to ${parentEmail}`);
//       return null;
//     } catch (error) {
//       console.error('Error sending payment receipt:', error);
      
//       // Update payment document with error
//       await snapshot.ref.update({
//         receiptSent: false,
//         receiptError: error.message,
//       });
      
//       return null;
//     }
//   });

// /**
//  * Trigger: When a payment balance reaches zero
//  * Action: Update enrollment status to 'paid'
//  */
// export const updateEnrollmentOnFullPayment = functions.firestore
//   .document('payments/{paymentId}')
//   .onCreate(async (snapshot, context) => {
//     const paymentData = snapshot.data();
    
//     // Skip if no enrollment ID
//     if (!paymentData.enrollmentId) {
//       return null;
//     }
    
//     try {
//       // Check if balance is zero or negative (fully paid)
//       if (paymentData.balanceRemaining <= 0) {
//         // Update enrollment status to 'paid'
//         await db.collection('enrollments').doc(paymentData.enrollmentId).update({
//           paymentStatus: 'paid',
//           status: 'approved', // Auto-approve when fully paid
//           updatedAt: admin.firestore.FieldValue.serverTimestamp(),
//         });
        
//         console.log(`Enrollment ${paymentData.enrollmentId} marked as paid`);
//       }
      
//       return null;
//     } catch (error) {
//       console.error('Error updating enrollment status:', error);
//       return null;
//     }
//   });

// /**
//  * Scheduled function to check for overdue payments
//  * Runs daily at midnight
//  */
// export const checkOverduePayments = functions.pubsub
//   .schedule('0 0 * * *') // Every day at midnight
//   .timeZone('Asia/Manila') // Philippine time
//   .onRun(async (context) => {
//     try {
//       // Get current date
//       const now = admin.firestore.Timestamp.now();
      
//       // Query enrollments with payment status 'partial' and have nextPaymentDueDate
//       const overdueQuery = await db.collection('enrollments')
//         .where('paymentStatus', '==', 'partial')
//         .where('nextPaymentDueDate', '<', now)
//         .get();
      
//       console.log(`Found ${overdueQuery.size} overdue payments`);
      
//       // Process each overdue payment
//       const batch = db.batch();
      
//       overdueQuery.forEach((doc) => {
//         const enrollmentData = doc.data();
        
//         // Add to notifications collection
//         const notificationRef = db.collection('notifications').doc();
//         batch.set(notificationRef, {
//           type: 'payment_overdue',
//           studentId: enrollmentData.studentId,
//           enrollmentId: doc.id,
//           title: 'Payment Overdue',
//           message: `Payment for student ${enrollmentData.studentInfo.firstName} ${enrollmentData.studentInfo.lastName} is overdue. Please contact the parent.`,
//           createdAt: admin.firestore.FieldValue.serverTimestamp(),
//           status: 'unread',
//           recipientRoles: ['admin', 'supervisor', 'cashier'],
//         });
        
//         // Update enrollment with overdue flag
//         batch.update(doc.ref, {
//           isOverdue: true,
//           overdueAt: admin.firestore.FieldValue.serverTimestamp(),
//         });
//       });
      
//       // Commit batch
//       await batch.commit();
      
//       return null;
//     } catch (error) {
//       console.error('Error checking overdue payments:', error);
//       return null;
//     }
//   });

// /**
//  * API Endpoint: Generate payment receipt PDF
//  */
// export const generateReceiptPdf = functions.https.onCall(async (data, context) => {
//   // Check if user is authenticated
//   if (!context.auth) {
//     throw new functions.https.HttpsError(
//       'unauthenticated',
//       'You must be logged in to generate a receipt.'
//     );
//   }
  
//   try {
//     const { paymentId } = data;
    
//     if (!paymentId) {
//       throw new functions.https.HttpsError(
//         'invalid-argument',
//         'Payment ID is required.'
//       );
//     }
    
//     // Get payment data
//     const paymentDoc = await db.collection('payments').doc(paymentId).get();
    
//     if (!paymentDoc.exists) {
//       throw new functions.https.HttpsError(
//         'not-found',
//         `Payment with ID ${paymentId} not found.`
//       );
//     }
    
//     const paymentData = paymentDoc.data();
//     paymentData.id = paymentId;
    
//     // Get student data
//     const studentDoc = await db.collection('students').doc(paymentData.studentId).get();
    
//     if (!studentDoc.exists) {
//       throw new functions.https.HttpsError(
//         'not-found',
//         `Student with ID ${paymentData.studentId} not found.`
//       );
//     }
    
//     const studentData = studentDoc.data();
    
//     // Generate receipt HTML
//     const receiptHtml = generateReceiptHtml(paymentData, studentData);
    
//     // This would normally use a PDF generation service like puppeteer or PDF.js
//     // For simplicity, we're just returning the HTML here
//     // In a real implementation, you would convert this to a PDF
//     return {
//       success: true,
//       html: receiptHtml,
//       // pdfUrl: would be a download URL if we generated a PDF
//     };
//   } catch (error) {
//     console.error('Error generating receipt PDF:', error);
//     throw new functions.https.HttpsError('internal', error.message);
//   }
// });